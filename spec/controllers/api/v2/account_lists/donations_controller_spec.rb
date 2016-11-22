require 'spec_helper'

describe Api::V2::AccountLists::DonationsController, type: :controller do
  let(:factory_type) { :donation }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account) { create(:donor_account) }
  let!(:designation_account) { create(:designation_account) }
  let!(:donations) { create_list(:donation, 2, donor_account: donor_account, designation_account: designation_account, amount: 10.00) }
  let(:donation) { donations.first }
  let(:id) { donation.id }

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  let(:resource) { donation }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:donation) }
  let(:incorrect_attributes) { { donation_date: nil } }
  let(:unpermitted_attributes) { nil }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'
end
