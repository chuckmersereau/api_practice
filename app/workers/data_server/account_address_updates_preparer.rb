# Prepares AccountList for graceful switch to automatic donor address updates
# See docs for DataServer::ContactAddressUpdatesPrep for details
class DataServer::AccountAddressUpdatesPreparer
  include Sidekiq::Worker
  sidekiq_options unique: true, queue: :import, backtrace: false

  def perform(account_list_id)
    account_list = AccountList.find_by(id: account_list_id)
    return unless account_list
    data_server_org_ids = Organization.using_data_server.pluck(:id)
    account_list
      .contacts.joins(:donor_accounts)
      .where(donor_accounts: { organization_id: data_server_org_ids })
      .find_each(&method(:prep_for_address_auto_updates))

    logger.info('Account #{account_list_id} prepped for DataServer address updates')
  end

  private

  def prep_for_address_auto_updates(contact)
    DataServer::ContactAddressUpdatesPrep.new(contact)
                                         .prep_for_address_auto_updates
  end
end
