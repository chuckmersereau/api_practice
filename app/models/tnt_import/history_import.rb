class TntImport::HistoryImport
  def initialize(account_list, tnt_contacts, xml)
    @account_list = account_list
    @tnt_contacts = tnt_contacts
    @xml = xml
  end

  def import_history
    return unless @xml['History'].present?
    tnt_history = {}
    tnt_history_id_to_appeal_id = {}

    Array.wrap(@xml['History']['row']).each do |row|
      task = Retryable.retryable do
        @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize
      end

      task.attributes = {
        activity_type: TntImport::TntCodes.task_type(row['TaskTypeID']),
        subject: subject(row),
        start_at: DateTime.parse(row['HistoryDate']),
        completed_at: DateTime.parse(row['HistoryDate']),
        completed: true,
        result: TntImport::TntCodes.history_result(row['HistoryResultID'])
      }

      tnt_history_id_to_appeal_id[row['id']] = row['AppealID'] if row['AppealID'].present?

      next unless task.save
      # Add any notes as a comment
      task.activity_comments.create(body: row['Notes'].strip) if row['Notes'].present?
      tnt_history[row['id']] = task
    end

    contacts_by_tnt_appeal_id = {}

    # Add contacts to tasks
    Array.wrap(@xml['HistoryContact']['row']).each do |row|
      contact = @tnt_contacts[row['ContactID']]
      task = tnt_history[row['HistoryID']]
      next unless contact && task

      Retryable.retryable times: 3, sleep: 1 do
        task.contacts << contact unless task.contacts.reload.include?(contact)
      end

      tnt_appeal_id = tnt_history_id_to_appeal_id[row['HistoryID']]
      if tnt_appeal_id
        contacts_by_tnt_appeal_id[tnt_appeal_id] ||= []
        contacts_by_tnt_appeal_id[tnt_appeal_id] << contact
      end
    end

    [tnt_history, contacts_by_tnt_appeal_id]
  end

  def subject(row)
    row['Description'] || TntImport::TntCodes.task_type(row['TaskTypeID'])
  end
end
