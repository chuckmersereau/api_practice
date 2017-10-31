require 'rails_helper'

RSpec.describe Contact::Filter::StartedGivingRange do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '#query' do
    let!(:first_contact) do
      create(:contact, account_list: account_list, pledge_amount: 0.0, first_donation_date: 4.months.ago)
    end
    let!(:second_contact) do
      create(:contact, account_list: account_list, pledge_amount: 20.00, first_donation_date: 3.months.ago)
    end
    let!(:third_contact) do
      create(:contact, account_list: account_list, pledge_amount: 40.00, first_donation_date: 7.months.ago)
    end
    let!(:fourth_contact) do
      create(:contact, account_list: account_list, pledge_amount: 40.00, first_donation_date: nil)
    end

    let(:contacts) { Contact.all }

    context 'contacts that have started giving within date range' do
      it 'returns the correct contacts' do
        expect(
          described_class.query(
            contacts,
            { started_giving_range: Range.new(5.months.ago.to_datetime, 2.months.ago) },
            [account_list]
          )
        ).to eq([second_contact])
      end
    end
  end
end
