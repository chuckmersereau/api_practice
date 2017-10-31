require 'rails_helper'

RSpec.describe Contact::Filter::PledgeAmountIncreasedRange do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '#query' do
    let!(:increasing_contact) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 150,
        pledge_frequency: 1,
        first_donation_date: 4.months.ago
      )
    end
    let!(:second_contact) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 20.00,
        first_donation_date: 3.months.ago
      )
    end
    let!(:third_contact) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 40.00,
        first_donation_date: 7.months.ago
      )
    end

    let!(:first_partner_status_log) do
      create(
        :partner_status_log,
        contact: increasing_contact,
        pledge_amount: 50.00,
        pledge_frequency: 1,
        recorded_on: 2.months.ago
      )
    end
    let!(:second_partner_status_log) do
      create(
        :partner_status_log,
        contact: increasing_contact,
        pledge_amount: 50.00,
        pledge_frequency: 0.5,
        recorded_on: 1.month.ago
      )
    end
    let!(:third_partner_status_log) do
      create(
        :partner_status_log,
        contact: second_contact,
        pledge_amount: 60.00,
        pledge_frequency: 0.5,
        recorded_on: 2.months.ago
      )
    end
    let!(:fourth_partner_status_log) do
      create(
        :partner_status_log,
        contact: second_contact,
        pledge_amount: 40.00,
        pledge_frequency: 0.5,
        recorded_on: 1.month.ago
      )
    end
    let!(:fifth_partner_status_log) do
      create(
        :partner_status_log,
        contact: third_contact,
        pledge_amount: 50.00,
        pledge_frequency: 1,
        recorded_on: 5.months.ago
      )
    end
    let!(:sixth_partner_status_log) do
      create(
        :partner_status_log,
        contact: third_contact,
        pledge_amount: 50.00,
        pledge_frequency: 0.5,
        recorded_on: 3.months.ago
      )
    end

    let(:contacts) { Contact.all }

    context 'contacts that have increased their pledge amount and or frequency' do
      it 'returns the correct contacts' do
        expect(
          described_class.query(
            contacts,
            { pledge_amount_increased_range: Range.new(3.months.ago.to_datetime, DateTime.now) },
            nil
          )
        ).to eq([increasing_contact])
      end
    end
  end
end
