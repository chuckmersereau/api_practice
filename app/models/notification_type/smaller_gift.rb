class NotificationType::SmallerGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if smaller_gift?(contact)
  end

  def smaller_gift?(contact)
    return unless contact.pledge_frequency&.positive? && contact.pledge_amount

    donations = contact.donations.without_gift_aid.reorder(donation_date: :asc)
    return unless donations.any?

    last_donation_date = donations.last&.donation_date
    start_last_donation_period = last_donation_date - pledge_frequency_as_time(contact.pledge_frequency)

    amount_given = donations.where(donation_date: start_last_donation_period..last_donation_date).sum(:amount)

    amount_given < contact.pledge_amount && !NotificationType::RecontinuingGift.had_recontinuing_gift?(contact)
  end

  def task_activity_type
    'To Do'
  end

  def task_description_template(notification = nil)
    if notification&.account_list&.designation_accounts&.many?
      _('%{contact_name} gave a gift of %{amount} on %{date} to %{designation}, '\
        'which is different from their pledge. Research the gift.')
    else
      _('%{contact_name} gave a gift of %{amount} on %{date}, which is different from their pledge. Research the gift.')
    end
  end

  private

  def pledge_frequency_as_time(pledge_frequency)
    {
      0.23076923076923.to_d => 1.week,
      0.46153846153846.to_d => 2.weeks,
      1.0.to_d => 1.month,
      2.0.to_d => 2.months,
      3.0.to_d => 3.months,
      4.0.to_d => 4.months,
      6.0.to_d => 6.months,
      12.0.to_d => 1.year,
      24.0.to_d => 2.years
    }[pledge_frequency]
  end
end
