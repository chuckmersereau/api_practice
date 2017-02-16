class Contact::Filter::Country < Contact::Filter::Base
  def execute_query(contacts, filters)
    filters[:country] << nil if Array(filters[:country]).delete('none')
    contacts.where('addresses.country' => filters[:country],
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
