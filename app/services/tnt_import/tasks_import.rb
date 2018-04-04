class TntImport::TasksImport
  include Concerns::TntImport::DateHelpers
  include Concerns::TntImport::TaskHelpers
  include Concerns::TntImport::AppealHelpers

  def initialize(import, contact_ids_by_tnt_contact_id, xml)
    @import = import
    @user = import.user
    @account_list = import.account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml = xml
    @xml_tables = xml.tables
  end

  XML_TABLE_NAME = 'Task'.freeze
  XML_FOREIGN_KEY = 'TaskID'.freeze

  def import
    return unless xml_tables[XML_TABLE_NAME].present? && xml_tables['TaskContact'].present?

    new_tasks = []
    all_tasks = build_tasks

    contact_ids_with_new_tasks =
      xml_tables['TaskContact'].map do |contact_row|
        begin
          task, contact_id = create_task_for_contact!(contact_row, all_tasks)
          new_tasks << task
          contact_id
        rescue ActiveRecord::RecordInvalid
          nil
        end
      end

    update_contacts_task_counters!(contact_ids_with_new_tasks.compact)
    new_tasks
  end

  private

  attr_reader :xml_tables, :contact_ids_by_tnt_contact_id

  def subject(row)
    row['Description'] || TntImport::TntCodes.task_type(row['TaskTypeID'])
  end

  def build_tasks
    task_rows = xml_tables[XML_TABLE_NAME].select { |row| TntImport::TntCodes.import_task_type?(row['TaskTypeID']) }
    task_rows.map { |r| build_task_from_row(r) }
  end

  def build_task_from_row(row)
    task = Retryable.retryable { @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize }

    task.attributes = {
      activity_type: TntImport::TntCodes.task_type(row['TaskTypeID']),
      subject: subject(row),
      start_at: parse_date("#{row['TaskDate']} #{row['TaskTime'].split(' ').second}", @user)
    }

    add_assigned_to_as_tag(task, row)
    add_campaign_as_tag(task, row)

    task.completed = TntImport::TntCodes.task_status_completed?(row['Status'])
    task.completed_at = parse_date(row['LastEdit'], @user) if task.completed
    task
  end

  def add_assigned_to_as_tag(task, row)
    assigned_to_id = row['AssignedToUserID']
    return unless assigned_to_id

    username = @xml.find('User', assigned_to_id).try(:[], 'UserName')
    task.tag_list.add username
  end

  def add_campaign_as_tag(task, row)
    campaign_id = row[appeal_id_name]
    return unless campaign_id

    campaign_name = @xml.find(appeal_table_name, campaign_id).try(:[], 'Description')
    task.tag_list.add campaign_name
  end

  def create_task_for_contact!(contact_row, tasks)
    task_prototype = find_task_prototype(contact_row, tasks)
    contact_id = contact_ids_by_tnt_contact_id[contact_row['ContactID']]
    return unless task_prototype && contact_id

    task = create_task_from_prototype!(task_prototype, contact_id)

    ActivityContact.where(activity_id: task.id, contact_id: contact_id).first_or_create! do |activity_contact|
      activity_contact.skip_task_counter_update = true
    end
    task.reload if task.id

    [task, contact_id]
  end

  def find_task_prototype(contact_row, tasks)
    tasks.find { |t| t.remote_id == contact_row[XML_FOREIGN_KEY] }
  end

  def create_task_from_prototype!(prototype, contact_id)
    dup_task(prototype, contact_id).tap do |task|
      task.save!

      row = @xml.find(XML_TABLE_NAME, task.remote_id)
      import_comments_for_task(task: task, row: row)
    end
  end

  def dup_task(task, contact_id)
    return task.dup unless task.id

    if task.contacts.empty? || task.contacts.any? { |c| c.id == contact_id }
      task
    else
      task.dup.tap { |t| t.id = nil }
    end
  end

  def update_contacts_task_counters!(contact_ids)
    Contact.where(id: contact_ids).find_each(&:update_uncompleted_tasks_count)
  end
end
