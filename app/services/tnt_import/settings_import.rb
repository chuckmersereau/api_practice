class TntImport::SettingsImport
  def initialize(account_list, xml, override)
    @account_list = account_list
    @xml = xml
    @xml_tables = xml.tables
    @override = override
  end

  def import
    return unless @xml_tables['Property'].present?

    @xml_tables['Property'].each do |row|
      case row['PropName']
      when 'MonthlySupportGoal'
        @account_list.monthly_goal = row['PropValue'] if @override || @account_list.monthly_goal.blank?
      when 'MailChimpListId'
        mail_chimp_list_id = row['PropValue']
      when 'MailChimpAPIKey'
        mail_chimp_key = row['PropValue']
      end

      import_mail_chimp(@account_list, mail_chimp_list_id, mail_chimp_key) if mail_chimp_list_id && mail_chimp_key
    end
    @account_list.save
  end

  def import_mail_chimp(mail_chimp_list_id, mail_chimp_key, override)
    if @account_list.mail_chimp_account
      return unless override
      @account_list.mail_chimp_account.update(api_key: mail_chimp_key,
                                              primary_list_id: mail_chimp_list_id)
    else
      @account_list.create_mail_chimp_account(api_key: mail_chimp_key,
                                              primary_list_id: mail_chimp_list_id)
    end
  end
end
