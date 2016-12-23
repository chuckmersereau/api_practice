class Contact::Filter::AddressHistoric < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
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

    def empty?(_account_lists)
      false
    end

    def default_selection
      false
    end
  end
end
