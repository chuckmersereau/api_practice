class Contact::PartnerStatusGuesser
  def initialize(contact)
    @contact = contact
  end

  def assign_guessed_status
    # If they have a donor account id, they are at least a special donor
    # If they have given the same amount for the past 3 months, we'll assume they are
    # a monthly donor.
    gifts = donations.where(donor_account_id: contact.donor_account_ids,
                            designation_account_id: designation_account_ids)
                     .order('donation_date desc')
    latest_donation = gifts[0]

    return unless latest_donation

    pledge_frequency = contact.pledge_frequency
    pledge_amount = contact.pledge_amount

    if latest_donation.donation_date.to_time > 2.months.ago && latest_donation.channel == 'Recurring'
      status = 'Partner - Financial'
      pledge_frequency = 1 unless contact.pledge_frequency
      pledge_amount = latest_donation.amount unless contact.pledge_amount.to_i > 0
    else
      status = 'Partner - Special'
    end

    contact.update(status: status, pledge_frequency: pledge_frequency,
                   pledge_amount: pledge_amount)
  end

  private

  attr_reader :contact
  delegate :donations, to: :contact

  def designation_account_ids
    contact.account_list.designation_account_ids
  end
end
