class TntImport::TasksImport
  def initialize(account_list, contact_ids_by_tnt_contact_id, xml)
    @account_list = account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml = xml
    @xml_tables = xml.tables
  end

  def import
    return unless xml_tables['Task'].present? && xml_tables['TaskContact'].present?
    task_ids_by_tnt_task_id = {}

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
end
