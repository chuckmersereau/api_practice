class MailChimpAccountSerializer < ApplicationSerializer
  attributes :active,
             :api_key,
             :auto_log_campaigns,
             :lists_available_for_newsletters,
             :lists_link,
             :lists_present,
             :primary_list_name,
             :sync_all_active_contacts,
             :valid,
             :validate_key,
             :validation_error

  belongs_to :primary_list

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
