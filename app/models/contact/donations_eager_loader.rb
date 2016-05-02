class Contact::DonationsEagerLoader
  def initialize(account_list:, donations_scoper: nil, contacts_scoper: nil)
    @account_list = account_list
    @donations_scoper = donations_scoper
    @contacts_scoper = contacts_scoper
  end

  def contacts_with_donations
    contacts = scoped_contacts.to_a
    contacts.each do |contact|
      contact.loaded_donations = donations_for_contact(contact)
    end
    contacts
  end

  private

  def scoped_contacts
    contacts = @account_list.contacts
    contacts = @contacts_scoper.call(contacts) if @contacts_scoper
    contacts.includes(:contact_donor_accounts)
  end

  def donations_for_contact(contact)
    contact_donor_ids(contact).flat_map(&method(:donations_for_donor_id))
  end

  def contact_donor_ids(contact)
    # contact_donor_accounts is eager loaded below, so just use map and not
    # a join and pluck.
    contact.contact_donor_accounts.map(&:donor_account_id)
  end

  def donations_for_donor_id(donor_account_id)
    @donations_by_donor_id ||= scoped_donations.group_by(&:donor_account_id)
    @donations_by_donor_id[donor_account_id] || []
  end

  def scoped_donations
    donations = contact_donations
    donations = @donations_scoper.call(donations) if @donations_scoper
    donations
  end

  def contact_donations
    @account_list.scope_donations_by_designations(
      Donation.where(donor_account_id: all_contact_donor_ids)
    )
  end

  def all_contact_donor_ids
    scoped_contacts.joins(:contact_donor_accounts)
                   .pluck('contact_donor_accounts.donor_account_id')
  end
end
