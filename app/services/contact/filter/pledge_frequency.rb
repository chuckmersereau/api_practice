class Contact::Filter::PledgeFrequency < Contact::Filter::Base
  def execute_query(contacts, filters)
    frequencies_not_null = Array.wrap(filters[:pledge_frequency]) - ['null']
    return unless frequencies_not_null.present?
    contacts.where(pledge_frequency: frequencies_not_null)
  end

  def title
    _('Commitment Frequency')
  end

  def parent
    _('Commitment Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    Contact.pledge_frequencies.invert.to_a.collect { |a| { name: a[0], id: a[1] } }
  end
end
