require 'rails_helper'

RSpec.describe Contact::Filter::StoppedGivingRange do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let!(:designation_account) { create(:designation_account, account_lists: [account_list]) }

  describe '#query' do
    let!(:first_contact) do
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [build(:donor_account)],
        last_donation_date: 2.months.ago
      )
    end
    let!(:second_contact) do
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [build(:donor_account, account_number: '123')],
        pledge_amount: 20.00, last_donation_date: 4.months.ago
      )
    end
    let!(:third_contact) do
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [build(:donor_account, account_number: '1234')],
        pledge_amount: 40.00, pledge_frequency: 0.5
      )
    end
    let!(:fourth_contact) do
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [build(:donor_account, account_number: '12345')],
        pledge_amount: 40.00
      )
    end

    let!(:first_donation_from_second_contact) do
      create(
        :donation,
        donation_date: 6.months.ago,
        designation_account: account_list.designation_accounts.first,
        donor_account: second_contact.donor_accounts.first,
        amount: 50.00
      )
    end
    let!(:second_donation_from_second_contact) do
      create(
        :donation,
        donation_date: 5.months.ago,
        designation_account: account_list.designation_accounts.first,
        donor_account: second_contact.donor_accounts.first,
        amount: 50.00
      )
    end
    let!(:third_donation_from_second_contact) do
      create(
        :donation,
        donation_date: 4.months.ago,
        designation_account: account_list.designation_accounts.first,
        donor_account: second_contact.donor_accounts.first,
        amount: 50.00
      )
    end
    let!(:first_donation_from_third_contact) do
      create(
        :donation,
        donation_date: 4.months.ago,
        designation_account: account_list.designation_accounts.first,
        donor_account: third_contact.donor_accounts.first,
        amount: 20.00
      )
    end
    let!(:second_donation_from_third_contact) do
      create(
        :donation,
        donation_date: 2.months.ago,
        designation_account: account_list.designation_accounts.first,
        donor_account: third_contact.donor_accounts.first,
        amount: 20.00
      )
    end

    let(:contacts) { Contact.all }

    context 'contacts that have stopped giving within date range' do
      it 'returns the correct contacts' do
        expect(
          described_class.query(
            contacts,
            { stopped_giving_range: Range.new(6.months.ago.to_datetime, 1.month.ago.to_datetime) },
            [account_list]
          )
        ).to eq([second_contact])
      end
    end
  end
end
