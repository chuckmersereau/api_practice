class Contact::Filter::Region < Contact::Filter::Base
  def execute_query(contacts, filters)
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

  def custom_options
    [{ name: _('-- None --'), id: 'none' }] + account_lists.map(&:regions).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
  end
end
