class DuplicateTasksPerContact
  include Sidekiq::Worker

  LOG_DIR = 'worker_results'.freeze

  sidekiq_options queue: :default, unique: :until_executed

  # @param account_list [AccountList, Integer, nil] an optional +AccountList+
  #  (or its ID) that owns the Tasks duplicate
  # @param min_contacts [Integer] Tasks with more than this number of Contacts
  #   will be duplicated
  # @param upload_log [Boolean] should a log file be uploaded to AWS S3?
  def perform(account_list = nil, min_contacts = 100, upload_log = true)
    new_tasks = {}
    scope = task_scope(account_list)

    Task.transaction do
      scope.group('activities.id')
           .having('count(activity_contacts.id) >= ?', min_contacts)
           .find_each { |t| new_tasks[t.id] = duplicate_task!(t) }

      Task.import!(new_tasks.values.flatten, recursive: true)
    end

    account_list_id = account_list.is_a?(Integer) ? account_list : account_list&.id
    upload_log_to_s3(account_list_id, new_tasks, prefix: LOG_DIR) if upload_log
  end

  private

  def task_scope(account_list)
    scope = account_list ? Task.where(account_list: account_list) : Task

    scope.joins(:activity_contacts).includes(:comments)
  end

  def duplicate_task!(task)
    comment_attributes = task.comments.map { |c| c.attributes.slice('body') }

    new_tasks =
      task.contacts[1..-1].map do |contact|
        task.dup.tap do |t|
          t.assign_attributes(id: nil, contacts: [contact])
          comment_attributes.each { |attr| t.comments.build(attr) }
        end
      end

    # original task remains owned by the first contact
    task.update!(contacts: [task.contacts.first])

    new_tasks
  end

  def upload_log_to_s3(account_list_id, records, prefix: nil)
    started_at = Time.zone.now
    conn = Fog::Storage.new(provider: 'AWS',
                            aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
                            aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
    dir = conn.directories.get(ENV.fetch('AWS_BUCKET'))
    path = log_path(started_at, account_list_id, prefix: prefix)
    file = dir.files.new(key: path, body: log_body(records, started_at))
    file.save
    Rails.logger.fatal "Saved in #{ENV.fetch('AWS_BUCKET')} bucket at #{path}"
  end

  def log_path(started_at, account_list_id, prefix: nil, delimiter: '/')
    [
      prefix,
      ("account-list-#{account_list_id}" if account_list_id),
      "duplicate_tasks_per_contact__#{started_at}.log"
    ].compact.join(delimiter)
  end

  # @param records [Hash<Integer, Array<Task>]
  def log_body(records, started_at)
    body = "workers/duplicate_tasks_per_contact.rb: #{started_at}"
    rows = records.map { |id, tasks| [id, tasks.map(&:id).join(' ')].join("\t") }
    [body, ('=' * body.size), rows.join("\n"), 'Done!'].join("\n")
  end
end
