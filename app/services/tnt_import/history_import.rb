class TntImport::HistoryImport
  include Concerns::TntImport::DateHelpers

  def initialize(import, contact_ids_by_tnt_contact_id, xml)
    @import                        = import
    @user                          = import.user
    @account_list                  = import.account_list
    @contact_ids_by_tnt_contact_id = contact_ids_by_tnt_contact_id
    @xml                           = xml
    @xml_tables                    = xml.tables
  end

  def import_history
    contact_ids_by_tnt_appeal_id = Hash.new { |hash, key| hash[key] = [] }

    return contact_ids_by_tnt_appeal_id unless @xml_tables['History'].present?

    task_id_by_tnt_history_id       = {}
    tnt_appeal_id_by_tnt_history_id = {}

    @xml_tables['History'].each do |row|
      tnt_history_id = row['id']

      task = Retryable.retryable do
        @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize
      end

      task.attributes = {
        activity_type: TntImport::TntCodes.task_type(row['TaskTypeID']),
        subject: subject(row),
        completed_at: parse_date(row['HistoryDate'], @user),
        completed: true,
        result: TntImport::TntCodes.history_result(row['HistoryResultID'])
      }

      task.start_at ||= parse_date(row['HistoryDate'], @user)

      tnt_appeal_id_by_tnt_history_id[tnt_history_id] = row_appeal_id(row) if row_appeal_id(row).present?

      next unless task.save
      # Add any notes as a comment
      task.comments.create(body: row['Notes'].strip) if row['Notes'].present?
      task_id_by_tnt_history_id[tnt_history_id] = task.id
    end

    contact_ids_with_new_tasks = []

    # Add contacts to tasks
    @xml_tables['HistoryContact'].each do |row|
      tnt_contact_id = row['ContactID']
      contact_id     = @contact_ids_by_tnt_contact_id[tnt_contact_id]
      tnt_history_id = row['HistoryID']
      task_id        = task_id_by_tnt_history_id[tnt_history_id]

      next unless contact_id && task_id

      Retryable.retryable times: 3, sleep: 1 do
        ActivityContact.where(activity_id: task_id, contact_id: contact_id).first_or_create! do |activity_contact|
          activity_contact.skip_task_counter_update = true

          contact_ids_with_new_tasks << contact_id
        end
      end

      tnt_appeal_id = tnt_appeal_id_by_tnt_history_id[row['HistoryID']]
      contact_ids_by_tnt_appeal_id[tnt_appeal_id] << contact_id if tnt_appeal_id
    end

    update_contacts_task_counters!(contact_ids_with_new_tasks)

    contact_ids_by_tnt_appeal_id
  end

  def subject(row)
    row['Description'] || TntImport::TntCodes.task_type(row['TaskTypeID'])
  end

  private

  def row_appeal_id(row)
    row['AppealID'] || row['CampaignID']
  end

  def update_contacts_task_counters!(contact_ids)
    Contact.where(id: contact_ids).find_each(&:update_uncompleted_tasks_count)
  end
end
