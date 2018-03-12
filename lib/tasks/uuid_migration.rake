namespace :mpdx do
  task ensure_uuids: :environment do
    tables_for_uuid_fill = %w(activities activity_comments activity_contacts appeal_contacts appeal_excluded_appeal_contacts)
    tables_for_uuid_fill.each do |table_name|
      sql = "UPDATE #{table_name} SET uuid = uuid_generate_v4() WHERE uuid IS NULL;"
      puts "-- execute(#{sql})"
      ActiveRecord::Base.connection.execute sql
    end
  end

  # this runs really slow when the rails server is on and has database connections
  task readd_indexes: :environment do
    path = Rails.root.join('db', 'dropped_indexes.csv')

    raise "indexes file doesn't exist!" unless File.exist?(path)

    CSV.read(path, headers: true).each do |index_row|
      puts "attempting to add index: #{index_row['indexname']}"
      next unless ActiveRecord::Base.connection.table_exists?(index_row['tablename'])
      ActiveRecord::Base.connection.execute index_row['indexdef'].sub('INDEX', 'INDEX CONCURRENTLY IF NOT EXISTS')
    end
  end

  task index_created_at: :environment do
    tables_query = "SELECT DISTINCT table_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                    and column_name = 'id' and data_type = 'uuid'"
    ActiveRecord::Base.connection.execute(tables_query).each do |foreign_table_row|
      table = foreign_table_row['table_name']

      next if ActiveRecord::Base.connection.index_exists?(table, :created_at)
      next unless ActiveRecord::Base.connection.column_exists?(table, :created_at)

      puts "indexing #{table}"
      ActiveRecord::Base.connection.add_index table, :created_at, algorithm: :concurrently
    end
  end

  # a task that sets the status of sidekiq
  # This will change the counts of running instances, so don't do it if you don't know for sure.
  # It will use your local aws config, so make sure you run `aws configure` before starting here.
  #
  # To turn sidekiq on: rake mpdx:set_sidekiq
  #
  # To turn sidekiq off: rake mpdx:set_sidekiq[false], or if you're using zsh: rake mpdx:set_sidekiq\[false\]
  #
  # For extra excitement, you can change the status of production by setting the second arg to 'production':
  # rake mpdx:set_sidekiq[true, production]
  task :set_sidekiq, [:up, :env] => [:environment] do |_t, args|
    args.with_defaults(up: true, env: 'staging')
    direction = args[:up] != 'false' ? :up : :down
    env_name = args[:env]

    puts "Turning #{env_name} sidekiq #{args[:up] != 'false' ? 'on' : 'off'}"
    confirm do
      count = env_name == 'production' ? 8 : 2
      cluster = env_name == 'production' ? 'prod' : 'stage'

      container_name = lambda do |n, env|
        "mpdx_api-#{env}-sidekiq-#{n}-sv2"
      end

      desired_count = direction == :up ? 1 : 0
      count.times do |i|
        service_name = container_name.call(i, env_name)
        system "#{access_args} aws ecs update-service --cluster #{cluster} --service #{service_name} --desired-count #{desired_count}"
      end
    end
  end

  # a task that sets the status of the rails app
  # This will change the counts of running instances, so don't do it if you don't know for sure.
  # It will use your local aws config, so make sure you run `aws configure` before starting here.
  #
  # To turn the application on: rake mpdx:set_application_status
  #
  # To turn the application off: rake mpdx:set_application_status[false], or if you're using zsh: rake mpdx:set_application_status\[false\]
  #
  # For extra excitement, you can change the status of production by setting the second arg to 'production':
  # rake mpdx:set_application_status[true, production]
  task :set_application_status, [:up, :env] => [:environment] do |_t, args|
    args.with_defaults(up: true, env: 'staging')
    direction = args[:up] != 'false' ? :up : :down

    puts "Turning #{args[:env]} application #{args[:up] != 'false' ? 'on' : 'off'}"
    confirm do
      count = if direction == :up
                args[:env] == 'production' ? 8 : 2
              else
                0
              end
      cluster = args[:env] == 'production' ? 'prod' : 'stage'

      container_name = "mpdx_api-#{args[:env]}-app-sv2"

      system "#{access_args} aws ecs update-service --cluster #{cluster} --service #{container_name} --desired-count #{count}"
    end
  end

  def confirm
    puts 'Are you sure? (yes/n)'
    input = STDIN.gets.strip
    if input == 'yes'
      puts 'OK...'

      yield
    else
      puts 'So sorry for the confusion'
    end
  end

  def access_args
    aws_home = `echo $AWS_HOME`.sub("\n", '')
    cred_lines = File.readlines(aws_home + '/credentials')
    access_key = cred_lines.find { |l| l.start_with? 'aws_access_key_id' }.to_s.split(' = ').last.sub("\n", '')
    secret_key = cred_lines.find { |l| l.start_with? 'aws_secret_access_key' }.to_s.split(' = ').last.sub("\n", '')
    "AWS_ACCESS_KEY_ID=#{access_key} AWS_SECRET_ACCESS_KEY=#{secret_key}"
  end

  # delete all of the import processes that are currently pending
  task drain_sidekiq: :environment do
    Sidekiq::Queue.new('api_account_list_import_data').each(&:delete)
  end

  # re-enqueue all of the import tasks that we previously killed
  task refill_import_queue: :environment do
    # code pulled from AccountListImportDataEnqueuerWorker
    active_users = User.where('current_sign_in_at >= ?', 2.months.ago)
    account_list_scope = AccountList.with_linked_org_accounts
                                    .has_users(active_users)
                                    .where('last_download_attempt_at IS NULL OR last_download_attempt_at <= ?', 12.hours.ago)

    ids = account_list_scope.pluck(:id)
    ids.each do |account_list_id|
      Sidekiq::Client.push(
        'class' => AccountList,
        'args'  => [account_list_id, :import_data],
        'queue' => :api_account_list_import_data
      )
    end
  end
end
