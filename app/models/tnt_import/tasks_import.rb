class TntImport::TasksImport
  def initialize(account_list, tnt_contacts, xml)
    @account_list = account_list
    @tnt_contacts = tnt_contacts
    @xml = xml
  end

  def import
    return unless xml['Task'].present? && xml['TaskContact'].present?
    tnt_tasks = {}

    Array.wrap(xml['Task']['row']).each do |row|
      task = Retryable.retryable do
        @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize
      end

      task.attributes = {
        activity_type: TntImport::TntCodes.task_type(row['TaskTypeID']),
        subject: row['Description'],
        start_at: DateTime.parse(row['TaskDate'] + ' ' + DateTime.parse(row['TaskTime']).strftime('%I:%M%p'))
      }
      next unless task.save
      # Add any notes as a comment
      task.activity_comments.create(body: row['Notes'].strip) if row['Notes'].present?
      tnt_tasks[row['id']] = task
    end

    # Add contacts to tasks
    Array.wrap(xml['TaskContact']['row']).each do |row|
      next unless tnt_contacts[row['ContactID']] && tnt_tasks[row['TaskID']]
      tnt_tasks[row['TaskID']].contacts << tnt_contacts[row['ContactID']] unless tnt_tasks[row['TaskID']].contacts.include? tnt_contacts[row['ContactID']]
    end

    tnt_tasks
  end

  private

  attr_reader :xml, :tnt_contacts
end
