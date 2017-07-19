class Contact::Filter::Region < Contact::Filter::Base
  def execute_query(contacts, filters)
    region_filters = parse_list(filters[:region])
    region_filters << nil if region_filters.delete('none')
    contacts.where('addresses.region' => region_filters,
                   'addresses.historic' => filters[:address_historic] == 'true')
            .joins(:addresses)
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:regions).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
  end
end
