class Contact::DupContactsMerge
  def initialize(account_list:, contact:)
    @account_list = account_list
    @contact = contact
  end

  def find_duplicates
    contacts_with_the_same_name_as(contact).select do |contact_with_the_same_name|
      contacts_have_a_matching_donor_account?(contact, contact_with_the_same_name) ||
        contacts_have_a_matching_address?(contact, contact_with_the_same_name)
    end
  end

  def merge_duplicates
    find_duplicates.each do |contact_to_merge|
      contact.merge(contact_to_merge)
    end

    contact.reload
    contact.merge_people
    contact.merge_addresses
  end

  private

  attr_accessor :account_list, :contact

  def contacts_with_the_same_name_as(contact)
    account_list.contacts.includes(:addresses, :donor_accounts).where.not(id: contact.id).where(name: contact.name)
  end

  def contacts_have_a_matching_donor_account?(contact_a, contact_b)
    (contact_a.donor_accounts & contact_b.donor_accounts).present?
  end

  def contacts_have_a_matching_address?(contact_a, contact_b)
    contact_a.addresses.any? do |address_a|
      contact_b.addresses.any? do |address_b|
        address_a.equal_to?(address_b)
      end
    end
  end
end
