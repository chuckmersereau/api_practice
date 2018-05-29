class Contact::Filter::PrimaryAddress < Contact::Filter::Base
  def execute_query(contacts, filters)
    case filters[:primary_address].to_s
    when 'primary'
      contacts.primary_addresses
    when 'active'
      contacts.non_historical_addresses
    when 'inactive'
      contacts.historical_addresses
    else
      contacts
    end
  end

  def title
    _('Address Type')
  end

  def parent
    _('Contact Location')
  end

  def type
    'multiselect'
  end

  def default_options
    []
  end

  def default_selection
    'primary, null'
  end

  def custom_options
    [
      { name: _('Primary'), id: 'primary' },
      { name: _('Active'), id: 'active' },
      { name: _('InActive'), id: 'inactive' },
      { name: _('All'), id: 'null' }
    ]
  end

  def valid_filters?(filters)
    %w(primary active inactive).include?(filters[:primary_address])
  end
end
