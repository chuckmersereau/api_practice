class DuplicateTasksPerContact
  include Sidekiq::Worker

  LOG_DIR = 'worker_results'.freeze

  def initialize
    @new_ids = {}
  end

  # @param account_list [AccountList, Integer, nil] an optional +AccountList+
  #  (or its ID) that owns the Tasks duplicate
  # @param min_contacts [Integer] Tasks with more than this number of Contacts
  #   will be duplicated
  # @param upload_log [Boolean] should a log file be uploaded to AWS S3?
  def perform(account_list: nil, min_contacts: 100, upload_log: true)
    scope = task_scope(account_list)

    scope.group('activities.id')
         .having('count(activity_contacts.id) >= ?', min_contacts)
         .find_each(&method(:duplicate_task!))

    account_list_id = account_list.is_a?(Integer) ? account_list : account_list&.id
    upload_log_to_s3(account_list_id, @new_ids, prefix: LOG_DIR) if upload_log
  end

  private

  def task_scope(account_list)
    scope = account_list ? Task.where(account_list: account_list) : Task

    scope.joins(:activity_contacts).includes(:comments)
  end

  def duplicate_task!(task)
    comment_attributes = task.comments.map { |c| c.attributes.slice('body') }

    Task.transaction do
      new_ids =
        task.contacts[1..-1].map do |contact|
          t = task.dup
          t.assign_attributes(uuid: nil, contacts: [contact])
          comment_attributes.each { |attr| t.comments.build(attr) }
          t.save!
          t.id
        end

      task.update!(contacts: [task.contacts.first])

      @new_ids[task.id] = new_ids
    end
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

  def log_body(records, started_at)
    body = "workers/duplicate_tasks_per_contact.rb: #{started_at}"
    rows = records.map { |id, ids| [id, ids.join(' ')].join("\t") }
    [body, ('=' * body.size), rows.join("\n"), 'Done!'].join("\n")
  end
end
