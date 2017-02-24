require 'rails_helper'

describe Api::V2::AccountLists::DonationsController, type: :controller do
  let(:factory_type) { :donation }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let!(:designation_account) { create(:designation_account) }
  let!(:donations) do
    create_list(:donation, 2, donor_account: donor_account,
                              designation_account: designation_account,
                              amount: 10.00,
                              donation_date: Date.today)
  end
  let(:donation) { donations.first }
  let(:id) { donation.uuid }

  before do
    donation.update(donation_date: 2.days.ago)
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  let(:resource) { donation }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:filter_param) { { donation_date: "#{1.day.ago}..#{1.day.from_now}" } }
  let(:sorting_param) { :donation_date }
  let(:correct_attributes) { attributes_for(:donation) }
  let(:incorrect_attributes) { { donation_date: nil } }
  let(:unpermitted_attributes) { nil }

  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list_id
        }
      }
    }
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'
end
