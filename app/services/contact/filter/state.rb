class Contact::Filter::State < Contact::Filter::Base
  def execute_query(contacts, filters)
    state_filters = filters[:state].split(',').map(&:strip)
    state_filters << nil if state_filters.delete('none')
    contacts.where('addresses.state' => state_filters,
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:states).flatten.uniq.select(&:present?).map { |state| { name: state, id: state } }
  end
end
