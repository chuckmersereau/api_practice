class ExpectedTotalsReport::ReceivedDonations
  attr_reader :account_list, :filter_params

  def initialize(account_list:, filter_params: nil)
    @account_list = account_list
    @filter_params = filter_params
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

  protected

  def donations_scope(donations = account_list.donations)
    return donations unless filter_params
    if filter_params[:designation_account_id]
      donations = donations.where(designation_account_id: filter_params[:designation_account_id])
    end
    if filter_params[:donor_account_id]
      donations = donations.where(donor_account_id: filter_params[:donor_account_id])
    end
    donations
  end

  private

  def donations_this_month
    @donations_this_month ||= donations_scope.where('donation_date >= ?', Date.current.beginning_of_month)
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
