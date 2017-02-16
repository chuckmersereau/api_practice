class AccountList::DeepReset
  def initialize(account_list_id, user_id)
    @account_list_id = account_list_id
    @user_id = user_id
  end

  def reset
    destroy_account_list if account_list.present?
    queue_donor_imports if user.present?
  end

  private

  def account_list
    @account_list ||= AccountList.find_by(id: @account_list_id)
  end

  def user
    @user ||= User.find_by(id: @user_id)
  end

  def destroy_account_list
    # Destroy the sync associations first to prevent the destruction of contacts
    # from triggering actual synced deletions in those external services.
    sync_associations.each do |association|
      account_list.public_send(association).try(:destroy!)
    end
    account_list.destroy!
  end

  def sync_associations
    [:prayer_letters_account, :google_integrations, :pls_account,
     :mail_chimp_account]
  end

  def queue_donor_imports
    user.organization_accounts.each(&:queue_import_data)
  end
end
