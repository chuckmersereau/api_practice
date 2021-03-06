class Contact::Filter::DonationAmountRange < Contact::Filter::Base
  def execute_query(contacts, filters)
    sanitize_filters(filters)
    contacts = contacts.joins(donor_accounts: [:donations])
    if filters[:donation_amount_range][:min].present?
      contacts = contacts.where('donations.amount >= :donation_amount_min AND '\
                                'donations.designation_account_id IN (:designation_account_ids)',
                                donation_amount_min: filters[:donation_amount_range][:min],
                                designation_account_ids: designation_account_ids)
    end
    if filters[:donation_amount_range][:max].present?
      contacts = contacts.where('donations.amount <= :donation_amount_max AND '\
                                'donations.designation_account_id IN (:designation_account_ids)',
                                donation_amount_max: filters[:donation_amount_range][:max],
                                designation_account_ids: designation_account_ids)
    end
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
    account_list_highest = account_lists.collect do |account_list|
      account_list.donations.where.not(amount: nil).reorder(:amount).last&.amount
    end
    highest_account_donation = account_list_highest.compact.max
    [{ name: _('Gift Amount Higher Than or Equal To'), id: 'min', placeholder: 0 },
     { name: _('Gift Amount Less Than or Equal To'), id: 'max', placeholder: highest_account_donation }]
  end

  def valid_filters?(filters)
    filters[:donation_amount_range].is_a?(Hash) &&
      (filters[:donation_amount_range][:min].present? || filters[:donation_amount_range][:max].present?)
  end

  def sanitize_filters(filters)
    [:min, :max].each do |option|
      next unless filters[:donation_amount_range][option].present?
      filters[:donation_amount_range][option] = filters[:donation_amount_range][option].gsub(/[^\.\d]/, '').to_f
    end
  end
end
