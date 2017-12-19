class DuplicateTasksPerContact
  include Sidekiq::Worker

  DEFAULT_AGE = 5.months

  def initialize
    @new_ids = {}
  end

  def perform(older_than = nil, upload_log: true)
    older_than ||= DEFAULT_AGE.ago

    task_scope.where('activities.created_at > ?', older_than)
              .group('activities.id')
              .having('count(activity_contacts.id) > 1')
              .find_each(&method(:duplicate_task!))

    upload_log_to_s3(@new_ids) if upload_log
  end

  private

  def task_scope
    Task.joins(:activity_contacts).includes(:comments)
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

  def upload_log_to_s3(records)
    started_at = Time.zone.now
    conn = Fog::Storage.new(provider: 'AWS',
                            aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
                            aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
    dir = conn.directories.get(ENV.fetch('AWS_BUCKET'))
    path = "duplicate_tasks_per_contact__#{started_at}.log"
    file = dir.files.new(key: path, body: log_body(records, started_at))
    file.save
    Rails.logger.fatal "Saved in #{ENV.fetch('AWS_BUCKET')} bucket at #{path}"
  end

  def log_body(records, started_at)
    body = "workers/duplicate_tasks_per_contact.rb: #{started_at}"
    rows = records.map { |id, ids| [id, ids.join(' ')].join("\t") }
    [body, ('=' * body.size), rows.join("\n"), 'Done!'].join("\n")
  end
end
