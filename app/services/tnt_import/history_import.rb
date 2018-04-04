class TntImport::HistoryImport < TntImport::TasksImport
  XML_TABLE_NAME = 'History'.freeze
  XML_FOREIGN_KEY = 'HistoryID'.freeze

  def import
    return {} unless xml_tables[XML_TABLE_NAME].present? && xml_tables['HistoryContact'].present?

    @tnt_appeal_id_by_tnt_history_id = {}

    all_tasks = build_tasks

    xml_tables['HistoryContact'].map do |contact_row|
      process_history_contact_row(contact_row, all_tasks)
    end

    contact_ids_by_tnt_appeal_id
  end

  private

  def build_tasks
    task_rows = xml_tables[XML_TABLE_NAME].select { |row| TntImport::TntCodes.import_task_type?(row['TaskTypeID']) }

    task_rows.map do |row|
      tnt_history_id = row['id']

      @tnt_appeal_id_by_tnt_history_id[tnt_history_id] = row[appeal_id_name] if row[appeal_id_name].present?

      build_task_from_row(row)
    end
  end

  def process_history_contact_row(contact_row, all_tasks)
    create_task_for_contact!(contact_row, all_tasks)
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def contact_ids_by_tnt_appeal_id
    # set default value of keys to an empty array so they can be pushed into later
    contact_ids_by_tnt_appeal_id = Hash.new { |hash, key| hash[key] = [] }

    xml_tables['HistoryContact'].each do |row|
      tnt_contact_id = row['ContactID']
      contact_id = @contact_ids_by_tnt_contact_id[tnt_contact_id]

      next unless contact_id

      tnt_appeal_id = @tnt_appeal_id_by_tnt_history_id[row[XML_FOREIGN_KEY]]
      contact_ids_by_tnt_appeal_id[tnt_appeal_id] << contact_id if tnt_appeal_id
    end

    contact_ids_by_tnt_appeal_id
  end

  def build_task_from_row(row)
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

    add_assigned_to_as_tag(task, row)
    add_campaign_as_tag(task, row)

    task.start_at ||= parse_date(row['HistoryDate'], @user)
    task
  end

  def find_task_prototype(contact_row, tasks)
    tasks.find { |t| t.remote_id == contact_row[XML_FOREIGN_KEY] }
  end

  def row_appeal_id(row)
    row[appeal_id_name]
  end
end
