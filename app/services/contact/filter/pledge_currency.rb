class Contact::Filter::PledgeCurrency < Contact::Filter::Base
  def execute_query(contacts, filters)
    pledge_currency_filters = filters[:pledge_currency].split(',').map(&:strip)
    default_currencies = account_lists.collect(&:default_currency)
    if (pledge_currency_filters & default_currencies).present?
      contacts.where(pledge_currency: [pledge_currency_filters, '', nil])
    else
      contacts.where(pledge_currency: pledge_currency_filters)
    end
  end

  def title
    _('Commitment Currency')
  end

  def parent
    _('Commitment Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_lists.map(&:currencies).flatten.uniq.select(&:present?).map { |a| { name: a, id: a } }
  end
end
