class Contact::Filter::City < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      filters[:city] << nil if Array(filters[:city]).delete('none')
      contacts.where('addresses.city' => filters[:city],
                     'addresses.historic' => filters[:address_historic] == 'true')
              .includes(:addresses)
              .references('addresses')
    end

    def title
      _('City')
    end

    def parent
      _('Contact Location')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' }] + account_list.cities.select(&:present?).map { |city| { name: city, id: city } }
    end
  end
end
