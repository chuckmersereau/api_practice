class Contact::SuggestedChangesUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_contact_suggested_changes_updater_worker

  def perform(user_id, since_time)
    @user = User.find_by_id(user_id)
    @since_time = since_time
    return unless @user

    contacts.each do |contact|
      Contact::SuggestedChangesUpdater.new(contact: contact).update_status_suggestions
    end
  end

  private

  def contacts
    contact_ids = @user.contacts.where(suggested_changes: nil).ids
    contact_ids += contact_ids_with_new_donations_since_time
    Contact.where(id: contact_ids)
  end

  def contact_ids_with_new_donations_since_time
    return [] if @since_time.blank?
    Contact.includes(donor_accounts: :donations)
           .where(account_list: @user.account_lists)
           .where('donations.created_at >= ?', @since_time)
           .ids
  end
end
