class Contact::Filter::Region < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filters[:region] << nil if Array(filters[:region]).delete('none')
      contacts.where('addresses.region' => filters[:region],
                     'addresses.historic' => filters[:address_historic] == 'true')
              .includes(:addresses)
              .references('addresses')
    end

    def title
      _('Region')
    end

    def parent
      _('Contact Location')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' }] + account_list.regions.select(&:present?).map { |a| { name: a, id: a } }
    end
  end
end
