module DonationReports
  class ReceivedDonations
    def initialize(account_list:, donations_scoper:)
      @account_list = account_list
      @donations_scoper = donations_scoper
    end

    def donations
      load_donors_and_donations
      @donations
    end

    def donors
      load_donors_and_donations
      @donors
    end

    private

    def donations_and_contacts
      Contact::DonationsEagerLoader.new(
        account_list: @account_list, donations_scoper: @donations_scoper
      ).donations_and_contacts
    end

    def donor_and_donation_info
      donations, contacts = donations_and_contacts
      donations_info = donations.map do |donation|
        DonationReports::DonationInfo.from_donation(donation,
                                                    @account_list.default_currency)
      end
      contacts_info = contacts.map do |contact|
        DonationReports::DonorInfo.from_contact(contact)
      end
      [donations_info, contacts_info]
    end

    def load_donors_and_donations
      return if @donations && @donors
      @donations, @donors = donor_and_donation_info
    end
  end
end
