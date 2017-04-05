class Contact::Filter::AddressValid < Contact::Filter::Base
  def execute_query(contacts, filters)
    self.contacts = contacts
    return contacts unless filters[:address_valid] == 'false'
    contacts_with_invalid_addresses
  end

  private

  attr_accessor :contacts

  def filter_scope
    contacts.includes(:addresses).references(:addresses)
  end

  def contacts_with_invalid_addresses
    filter_scope.where(contacts: { id: (contact_ids_with_duplicate_primary_addresses +
                                        contact_ids_with_address_valid_values_false) })
  end

  def contact_ids_with_address_valid_values_false
    filter_scope.where(addresses: { valid_values: false }).pluck(:addressable_id)
  end

  def contact_ids_with_duplicate_primary_addresses
    Address.select(:addressable_id)
           .where(addressable_type: 'Contact', addressable_id: contacts.ids, primary_mailing_address: true)
           .group(:addressable_id)
           .having('count(*) > 1')
           .pluck(:addressable_id)
  end
end
