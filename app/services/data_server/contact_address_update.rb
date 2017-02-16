DataServer::ContactAddressUpdate = Struct.new(:contact, :donor_account) do
  def update_from_donor_account
    return if contact_already_has_latest?

    Contact.transaction do
      if contact.primary_address&.source == 'DataServer'
        contact.primary_address.update!(primary_mailing_address: false)
      end
      contact.copy_address(address: latest_donor_address, source: 'DataServer',
                           source_donor_account_id: latest_donor_address.addressable_id)
    end
  end

  private

  def contact_already_has_latest?
    contact.addresses_including_deleted.any? { |a| a.equal_to?(latest_donor_address) }
  end

  def latest_donor_address
    @latest_donor_address ||= donor_account.addresses.reorder(created_at: :desc).first
  end
end
