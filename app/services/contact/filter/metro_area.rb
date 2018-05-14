class Contact::Filter::MetroArea < Contact::Filter::Base
  def execute_query(contacts, filters)
    metro_area_filters = parse_list(filters[:metro_area])
    metro_area_filters << nil if metro_area_filters.delete('none')
    contacts.where('addresses.metro_area' => metro_area_filters,
                   'addresses.historic' => filters[:address_historic] == 'true')
            .joins(:addresses)
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

  def custom_options
    account_list_areas = account_lists.collect(&:metro_areas)
                                      .flatten
                                      .uniq
                                      .reject(&:blank?)
                                      .map { |s| { name: _(s), id: s } }
    [{ name: _('-- None --'), id: 'none' }] + account_list_areas
  end
end
