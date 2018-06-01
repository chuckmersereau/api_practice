class TntImport::TasksImport
  include Concerns::TntImport::DateHelpers
  include Concerns::TntImport::AppealHelpers

  def initialize(import, contact_ids_by_tnt_contact_id, xml)
    @import = import
    @user = import.user
    @account_list = import.account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml = xml
    @xml_tables = xml.tables
  end

  def import
    return unless xml_tables[xml_table_name].present? && xml_tables['TaskContact'].present?

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
    task_rows = xml_tables[xml_table_name].select { |row| TntImport::TntCodes.import_task_type?(row['TaskTypeID']) }
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
    add_categories_as_tags(task, row)

    task.completed = TntImport::TntCodes.task_status_completed?(row['Status'])
    task.completed_at = parse_date(row['LastEdit'], @user) if task.completed
    task
  end

  def add_categories_as_tags(task, row)
    task.tag_list.add(row['Categories'], parse: true) if row['Categories'].present?
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

    task.reload

    [task, contact_id]
  end

  def find_task_prototype(contact_row, tasks)
    tasks.find { |t| t.remote_id == contact_row[xml_foreign_key] }
  end

  def create_task_from_prototype!(prototype, contact_id)
    dup_task(prototype, contact_id).tap do |task|
      task.skip_contact_task_counter_update = true

      task.activity_contacts.where(contact_id: contact_id).first_or_initialize do |activity_contact|
        activity_contact.skip_contact_task_counter_update = true
      end

      task.save!

      row = @xml.find(xml_table_name, task.remote_id)
      import_comments_for_task(task: task, row: row)
    end
  end

  def dup_task(task, contact_id)
    dupped_task = if task.id.blank?
                    task.dup
                  elsif task.contacts.empty? || task.contacts.any? { |c| c.id == contact_id }
                    task
                  else
                    task.dup.tap { |t| t.id = nil }
                  end

    task.comments.each { |c| dupped_task.comments << c.dup } if dupped_task != task

    dupped_task
  end

  def update_contacts_task_counters!(contact_ids)
    Contact.where(id: contact_ids).find_each(&:update_uncompleted_tasks_count)
  end

  def import_comments_for_task(task:, row: nil)
    notes = row.try(:[], 'Notes')
    tnt_task_type_id = row.try(:[], 'TaskTypeID')

    task.comments.where(body: notes.strip).first_or_create if notes.present?

    unsupported_type_name = ::TntImport::TntCodes.unsupported_task_type(tnt_task_type_id)
    if unsupported_type_name
      comment_body = _(%(This task was given the type "#{unsupported_type_name}" in TntConnect.))
      task.comments.where(body: comment_body).first_or_create
    end

    add_completed_by_as_comment(task, row) if task.completed

    task.comments
  end

  def add_completed_by_as_comment(task, row)
    completed_by_id = row['LoggedByUserID']
    return unless completed_by_id

    username = @xml.find('User', completed_by_id).try(:[], 'UserName')
    task.comments.where(body: "Completed By: #{username}").first_or_create if username
  end

  def xml_table_name
    'Task'
  end

  def xml_foreign_key
    'TaskID'
  end
end
