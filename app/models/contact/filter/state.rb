class Contact::Filter::State < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      filters[:state] << nil if Array(filters[:state]).delete('none')
      contacts.where('addresses.state' => filters[:state],
                     'addresses.historic' => filters[:address_historic] == 'true')
              .includes(:addresses)
              .references('addresses')
    end

    def title
      _('State')
    end

    def parent
      _('Contact Location')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      [{ name: _('-- None --'), id: 'none' }] + account_list.states.select(&:present?).map { |state| { name: state, id: state } }
    end
  end
end
