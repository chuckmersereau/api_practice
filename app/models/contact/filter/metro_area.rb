class Contact::Filter::MetroArea < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filters[:metro_area] << nil if Array(filters[:metro_area]).delete('none')
      contacts.where('addresses.metro_area' => filters[:metro_area],
                     'addresses.historic' => filters[:address_historic] == 'true')
              .includes(:addresses)
              .references('addresses')
    end

    def title
      _('Metro Area')
    end

    def parent
      _('Contact Location')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' }] + account_list.metro_areas.reject(&:blank?).map { |s| { name: _(s), id: s } }
    end
  end
end
