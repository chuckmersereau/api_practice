class Contact::DupContactsMergeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_contact_dup_contacts_merge_worker

  def perform(account_list_id, contact_id)
    @account_list = AccountList.find_by_id(account_list_id)
    @contact = Contact.find_by_id(contact_id)
    return unless @account_list && @contact

    Contact::DupContactsMerge.new(account_list: @account_list, contact: @contact).merge_duplicates
  end
end
