class Contact::Filter::City < Contact::Filter::Base
  def execute_query(contacts, filters)
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:cities).flatten.uniq.select(&:present?).map { |city| { name: city, id: city } }
  end
end
