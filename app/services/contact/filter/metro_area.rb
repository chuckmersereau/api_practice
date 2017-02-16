class Contact::Filter::MetroArea < Contact::Filter::Base
  def execute_query(contacts, filters)
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.collect(&:metro_areas).flatten.uniq.reject(&:blank?).map { |s| { name: _(s), id: s } }
  end
end
