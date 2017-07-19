require 'rails_helper'

RSpec.describe Contact::Filter::StartedGivingWithin do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '#query' do
    let!(:first_contact) { create(:contact, account_list: account_list, pledge_amount: 0.0, first_donation_date: 4.months.ago) }
    let!(:second_contact) { create(:contact, account_list: account_list, pledge_amount: 20.00, first_donation_date: 3.months.ago) }
    let!(:third_contact) { create(:contact, account_list: account_list, pledge_amount: 40.00, first_donation_date: 7.months.ago) }
    let!(:fourth_contact) { create(:contact, account_list: account_list, pledge_amount: 40.00, first_donation_date: nil) }
    let(:contacts) { Contact.all }

    context 'contacts that have started giving within date range' do
      it 'returns the correct contacts' do
        expect(described_class.query(contacts, { started_giving_within: Range.new(5.months.ago, 2.months.ago) }, [account_list])).to eq([second_contact])
      end
    end
  end
end
