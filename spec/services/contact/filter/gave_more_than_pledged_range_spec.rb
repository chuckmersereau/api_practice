require 'rails_helper'

RSpec.describe Contact::Filter::GaveMoreThanPledgedRange do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let!(:designation_account) { create(:designation_account, account_lists: [account_list]) }

  describe '#query' do
    let!(:first_contact) do
      create(:contact,
             account_list: account_list,
             donor_accounts: [build(:donor_account)])
    end
    let!(:second_contact) do
      create(:contact,
             account_list: account_list,
             donor_accounts: [build(:donor_account, account_number: '123')],
             pledge_amount: 20.00)
    end
    let!(:third_contact) do
      create(:contact,
             account_list: account_list,
             donor_accounts: [build(:donor_account, account_number: '1234')],
             pledge_amount: 40.00,
             pledge_frequency: 0.5)
    end
    let!(:fourth_contact) do
      create(:contact,
             account_list: account_list,
             donor_accounts: [build(:donor_account, account_number: '12345')],
             pledge_amount: 40.00)
    end
    let!(:first_donation_from_second_contact) do
      create(:donation,
             donation_date: 2.months.ago,
             designation_account: account_list.designation_accounts.first,
             donor_account: second_contact.donor_accounts.first,
             amount: 50.00)
    end
    let!(:second_donation_from_second_contact) do
      create(:donation,
             donation_date: 5.months.ago,
             designation_account: account_list.designation_accounts.first,
             donor_account: second_contact.donor_accounts.first,
             amount: 50.00)
    end
    let!(:first_donation_from_third_contact) do
      create(:donation,
             donation_date: 2.months.ago,
             designation_account: account_list.designation_accounts.first,
             donor_account: third_contact.donor_accounts.first,
             amount: 20.00)
    end
    let!(:second_donation_from_third_contact) do
      create(:donation,
             donation_date: 2.months.ago,
             designation_account: account_list.designation_accounts.first,
             donor_account: third_contact.donor_accounts.first,
             amount: 20.00)
    end

    let(:contacts) { Contact.all }

    context 'contacts that have started giving within date range' do
      it 'returns the correct contacts' do
        expect(
          described_class.query(
            contacts,
            { gave_more_than_pledged_range: Range.new(3.months.ago.to_date, 1.month.ago.to_date) },
            [account_list]
          )
        ).to match_array([second_contact])
      end
    end
  end
end
