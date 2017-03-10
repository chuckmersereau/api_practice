class Contact::Filter::City < Contact::Filter::Base
  def execute_query(contacts, filters)
    city_filters = filters[:city].split(',').map(&:strip)
    city_filters << nil if city_filters.delete('none')
    contacts.where('addresses.city' => city_filters,
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:cities).flatten.uniq.select(&:present?).map { |city| { name: city, id: city } }
  end
end
