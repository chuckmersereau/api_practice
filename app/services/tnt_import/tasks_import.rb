class TntImport::TasksImport
  def initialize(account_list, tnt_contacts, xml)
    @account_list = account_list
    @tnt_contacts = tnt_contacts
    @xml = xml
    @xml_tables = xml.tables
  end

  def import
    return unless xml_tables['Task'].present? && xml_tables['TaskContact'].present?
    tnt_tasks = {}

    xml_tables['Task'].each do |row|
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
      task.comments.where(body: row['Notes'].strip).first_or_initialize.save if row['Notes'].present?

      tnt_tasks[row['id']] = task
    end

    # Add contacts to tasks
    xml_tables['TaskContact'].each do |row|
      next unless tnt_contacts[row['ContactID']] && tnt_tasks[row['TaskID']]
      tnt_tasks[row['TaskID']].contacts << tnt_contacts[row['ContactID']] unless tnt_tasks[row['TaskID']].contacts.include? tnt_contacts[row['ContactID']]
    end

    tnt_tasks
  end

  private

  attr_reader :xml_tables, :tnt_contacts
end
