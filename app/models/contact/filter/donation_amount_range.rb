class Contact::Filter::DonationAmountRange < Contact::Filter::Base
  def execute_query(contacts, filters)
    sanitize_filters(filters)
    contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations])
    contacts = contacts.where('donations.amount >= ?', filters[:donation_amount_range][:min]) if filters[:donation_amount_range][:min].present?
    contacts = contacts.where('donations.amount <= ?', filters[:donation_amount_range][:max]) if filters[:donation_amount_range][:max].present?
    contacts
  end

  def title
    _('Gift Amount Range')
  end

  def parent
    _('Gift Details')
  end

  def type
    'text'
  end

  def custom_options
    highest_account_donation = account_lists.collect { |account_list| account_list.donations.where.not(amount: nil).pluck(:amount).uniq.sort.last }.flatten.max
    [{ name: _('Gift Amount Higher Than or Equal To'), id: 'min', placeholder: 0 },
     { name: _('Gift Amount Less Than or Equal To'), id: 'max', placeholder: highest_account_donation }]
  end

  def valid_filters?(filters)
    super && (filters[:donation_amount_range][:min].present? || filters[:donation_amount_range][:max].present?)
  end

  def sanitize_filters(filters)
    [:min, :max].each do |option|
      next unless filters[:donation_amount_range][option].present?
      filters[:donation_amount_range][option] = filters[:donation_amount_range][option].gsub(/[^\.\d]/, '').to_f
    end
  end
end
