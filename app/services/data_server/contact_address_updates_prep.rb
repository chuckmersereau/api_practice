# This class was written to help ease the transition for users from DataServer
# not auto-updating addresses from the donor system to updating them
# automatically. The idea would be that for current contacts, we would have them
# keep their addresses fixed if their address is different from that the donor
# system currently has so that the code change would not have a large scale
# immediate change of addresses. However, over the long term once the code
# change is completed, contacts whose primary address did match the primary
# address from DataServer would get new updates from DataServer marked as
# primary as they come through (unless they check a non-donor-system address as
# primary at some point).
class DataServer::ContactAddressUpdatesPrep
  def initialize(contact)
    @contact = contact
  end

  def prep_for_address_auto_updates
    fix_address_encodings
    @contact.merge_addresses
    update_primary_address_source
    import_addresses_from_donors
  end

  private

  def fix_address_encodings
    @contact.addresses.each do |contact_address|
      donor_addresses.each do |donor_address|
        contact_address.fix_encoding_if_equal(donor_address)
      end
    end
  end

  def update_primary_address_source
    mailing_address = @contact.reload_mailing_address
    return if mailing_address.new_record?
    unless mailing_address.primary_mailing_address?
      Sidekiq::Logging.logger.info("Mailing address not primary for #{@contact.id}")
    end

    latest_donor_address = donor_addresses.first
    if mailing_address.equal_to?(latest_donor_address)
      # The current mailing address matches what is most recent from DataServer,
      # so update that address's source to be from DataServer.
      donor_account_id = latest_donor_address.addressable_id
      mailing_address.update(source: 'DataServer',
                             source_donor_account_id: donor_account_id)
    else
      # The current mailing address does not match the most recent one from
      # DataServer. So what we are going to assume to make the transition to
      # auto-updating DataServer addresses easier for existing users is we are
      # going to mark the existing not-matching-DataServer address to be marked
      # as manual (even if it was originally from DataServer)
      mailing_address.update(source: Address::MANUAL_SOURCE)
    end
  end

  def import_addresses_from_donors
    donor_addresses.each do |address|
      next if @contact.addresses_including_deleted.any? { |a| a.equal_to?(address) }
      add_donor_address(address)
    end
  end

  def add_donor_address(donor_address)
    @contact.copy_address(address: donor_address, source: 'DataServer',
                          source_donor_account_id: donor_address.addressable_id)
  end

  def donor_addresses
    @donor_addresses ||=
      @contact.donor_accounts.flat_map(&:addresses).sort_by(&:created_at).reverse
  end
end
