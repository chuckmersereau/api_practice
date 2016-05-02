module ExpectedTotalsReport
  class ReceivedDonations
    def initialize(account_list)
      @account_list = account_list
    end

    def donation_rows
      donations_this_month.map do |donation|
        {
          type: 'received',
          contact: contacts_by_donor_id[donation.donor_account_id],
          donation_amount: donation.tendered_amount || donation.amount,
          donation_currency: donation.tendered_currency || donation.currency ||
            account_list.default_currency
        }
      end
    end

    private

    attr_reader :account_list

    def donations_this_month
      @donations_this_month ||=
        account_list
        .donations
        .where('donation_date >= ?', Date.current.beginning_of_month)
    end

    def contacts_by_donor_id
      @contacts_by_donor_id ||= group_contacts_by_donor_id
    end

    def group_contacts_by_donor_id
      donor_contacts.each_with_object({}) do |contact, contacts_by_donor_id|
        contact.donor_accounts.each do |donor_account|
          contacts_by_donor_id[donor_account.id] ||= contact
        end
      end
    end

    def donor_contacts
      account_list
        .contacts
        .joins(:contact_donor_accounts)
        .includes(:contact_donor_accounts)
        .where(contact_donor_accounts: { donor_account_id: donor_ids })
        .order('contacts.id')
    end

    def donor_ids
      donations_this_month.pluck(:donor_account_id)
    end
  end
end
