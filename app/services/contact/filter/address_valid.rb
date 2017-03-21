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
    filter_scope.where('addresses.valid_values = :valid OR contacts.id IN(:contact_ids)',
                       valid: false,
                       contact_ids: select_contact_ids_with_duplicate_primary_addresses)
  end

  def select_contact_ids_with_duplicate_primary_addresses
    Address.select(:addressable_id)
           .where(addressable_type: 'Contact', addressable_id: contacts.ids, primary_mailing_address: true)
           .group(:addressable_id)
           .having('count(*) > 1')
  end
end
