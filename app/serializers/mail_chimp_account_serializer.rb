class MailChimpAccountSerializer < ActiveModel::Serializer
  attributes :id, :api_key, :validation_error, :active, :validate_key, :auto_log_campaigns, :primary_list_id,
             :primary_list_name, :lists_link, :sync_all_active_contacts, :lists_present, :valid, :lists_available_for_newsletters

  def valid
    scope[:current_account_list].valid_mail_chimp_account
  end

  def lists_present
    object.lists.present?
  end

  def lists_available_for_newsletters
    object.lists_available_for_newsletters_formatted
  end
end
