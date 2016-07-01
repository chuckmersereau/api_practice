# This is to clean up duplicated donor account addresses resulting from an
# old way of doing the encoding for DataServer imports that didn't work with
# special characters (and caused duplicated addresses once we fixed it).
class OrgDonorAccountsAddressCleaner
  include Sidekiq::Worker
  sidekiq_options unique: true, queue: :import

  def self.queue_for_data_server_orgs
    Organization.using_data_server.pluck(:id).each_with_index do |org_id, index|
      perform_in(index * 1.minute, org_id)
    end
  end

  def perform(organization_id)
    donor_accounts_multi_addresses(organization_id).find_each(&:merge_addresses)
    update_addresses_source(organization_id)
    logger.info("Cleaned donor account addresses for org #{organization_id}")
  end

  private

  def donor_accounts_multi_addresses(organization_id)
    DonorAccount.where(organization_id: organization_id)
                .joins(:addresses).group('donor_accounts.id').having('count(*) > 1')
  end

  def update_addresses_source(organization_id)
    org = Organization.find(organization_id)
    return unless org.api_class = 'DataServer'

    Address.where(addressable_type: 'DonorAccount')
           .joins('INNER JOIN donor_accounts ON donor_accounts.id = addresses.addressable_id')
           .where(donor_accounts: { organization_id: org.id })
           .update_all(source: 'DataServer')
  end
end
