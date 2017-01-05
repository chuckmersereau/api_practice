class Contact::Filter::AddressHistoric < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('addresses.historic' => filters[:address_historic] == 'true')
            .includes(:addresses)
            .references('addresses')
  end

  def title
    _('Address No Longer Valid')
  end

  def parent
    _('Contact Location')
  end

  def type
    'single_checkbox'
  end

  def empty?
    false
  end

  def default_selection
    false
  end
end
