class Contact::Filter::Country < Contact::Filter::Base
  def execute_query(contacts, filters)
    country_filters = filters[:country].split(',').map(&:strip)
    country_filters << nil if country_filters.delete('none')
    contacts.where('addresses.country' => country_filters,
                   'addresses.historic' => filters[:address_historic] == 'true')
            .includes(:addresses)
            .references('addresses')
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
    [{ name: _('-- None --'), id: 'none' }] + account_lists.collect(&:countries).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
  end
end
