class Contact::Filter::Country < Contact::Filter::Base
  def execute_query(contacts, filters)
    country_filters = parse_list(filters[:country])
    country_filters << nil if country_filters.delete('none')
    contacts.where('addresses.country' => country_filters,
                   'addresses.historic' => filters[:address_historic] == 'true')
            .joins(:addresses)
  end

  def title
    _('Country')
  end

  def parent
    _('Contact Location')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_list_countries = account_lists.collect(&:countries)
                                          .flatten
                                          .uniq
                                          .select(&:present?)
                                          .map { |a| { name: a, id: a } }
    [{ name: _('-- None --'), id: 'none' }] + account_list_countries
  end
end
