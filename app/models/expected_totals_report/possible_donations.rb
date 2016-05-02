module ExpectedTotalsReport
  class PossibleDonations
    # Check back 3 years + 2 months of donation history to feed to the
    # LikelyDonation calculation.
    RECENT_DONATIONS_MONTHS_BACK = 12 * 3 + 2

    def initialize(account_list)
      @account_list = account_list
    end

    def donation_rows
      contacts_with_donations.map(&method(:row_for_contact)).compact
    end

    private

    attr_reader :account_list

    def row_for_contact(contact)
      received_this_month, likely_more = received_and_likely_more_amounts(contact)
      if likely_more > 0.0
        return { type: 'likely', contact: contact, donation_amount: likely_more,
                 donation_currency: contact.pledge_currency }
      end

      return if received_this_month > 0.0

      { type: 'unlikely', contact: contact, donation_amount: contact.pledge_amount,
        donation_currency: contact.pledge_currency }
    end

    def received_and_likely_more_amounts(contact)
      likely_donation = LikelyDonation.new(
        contact: contact, recent_donations: contact.loaded_donations,
        date_in_month: Date.current
      )
      [likely_donation.received_this_month, likely_donation.likely_more]
    end

    def contacts_with_donations
      Contact::DonationsEagerLoader.new(
        account_list: account_list,
        donations_scoper: lambda do |donations|
          donations.where('donation_date > ?', recent_donations_cutoff_date)
        end,
        contacts_scoper: lambda do |contacts|
          contacts.financial_partners.where('pledge_amount > 0')
        end
      ).contacts_with_donations
    end

    def recent_donations_cutoff_date
      RECENT_DONATIONS_MONTHS_BACK.months.ago.to_date.beginning_of_month
    end
  end
end
