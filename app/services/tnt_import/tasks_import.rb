class TntImport::TasksImport
  include Concerns::TntImport::DateHelpers
  include Concerns::TntImport::TaskHelpers

  def initialize(import, contact_ids_by_tnt_contact_id, xml)
    @import = import
    @user = import.user
    @account_list = import.account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml = xml
    @xml_tables = xml.tables
  end

  def import
    return unless xml_tables['Task'].present? && xml_tables['TaskContact'].present?
    task_ids_by_tnt_task_id = {}

    xml_tables['Task'].each do |row|
      next unless TntImport::TntCodes.import_task_type?(row['TaskTypeID'])

      task = build_task_from_row(row)

      next unless task.save

      import_comments_for_task(task: task, notes: row['Notes'], tnt_task_type_id: row['TaskTypeID'])

      task_ids_by_tnt_task_id[row['id']] = task.id
    end

    contact_ids_with_new_tasks = []

    # Add contacts to tasks
    xml_tables['TaskContact'].each do |row|
      task_id = task_ids_by_tnt_task_id[row['TaskID']]
      contact_id = contact_ids_by_tnt_contact_id[row['ContactID']]

      next unless task_id && contact_id

      ActivityContact.where(activity_id: task_id, contact_id: contact_id).first_or_create! do |activity_contact|
        activity_contact.skip_task_counter_update = true
        contact_ids_with_new_tasks << contact_id
      end
    end

    update_contacts_task_counters!(contact_ids_with_new_tasks)

    task_ids_by_tnt_task_id
  end

  private

  attr_reader :xml_tables, :contact_ids_by_tnt_contact_id

  def update_contacts_task_counters!(contact_ids)
    Contact.where(id: contact_ids).find_each(&:update_uncompleted_tasks_count)
  end

  def build_task_from_row(row)
    task = Retryable.retryable { @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize }

    task.attributes = {
      activity_type: TntImport::TntCodes.task_type(row['TaskTypeID']),
      subject: row['Description'],
      start_at: parse_date("#{row['TaskDate']} #{row['TaskTime'].split(' ').second}", @user)
    }

    task.completed = TntImport::TntCodes.task_status_completed?(row['Status'])
    task.completed_at = parse_date(row['LastEdit'], @user) if task.completed

    task
  end
end
