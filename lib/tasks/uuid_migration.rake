namespace :mpdx do
  task readd_indexes: :environment do
    path = Rails.root.join('db', 'dropped_indexes.csv')

    raise "indexes file doesn't exist!" unless File.exist?(path)

    CSV.read(path, headers: true).each do |index_row|
      puts "attempting to add index: #{index_row['indexname']}"
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
      next unless ActiveRecord::Base.connection.connection.column_exists?(table, :created_at)
      ActiveRecord::Base.connection.add_index table, :created_at, algorithm: :concurrently
    end
  end
end
