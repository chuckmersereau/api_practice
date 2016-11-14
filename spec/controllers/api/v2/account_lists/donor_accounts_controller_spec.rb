require 'spec_helper'

describe Api::V2::AccountLists::DonorAccountsController, type: :controller do
  let(:resource_type) { :donor_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let(:id) { donor_account.id }

  before do
    contact.donor_accounts << donor_account
  end

  let(:resource) { donor_account }
  let(:parent_path) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:donor_account) }

  include_examples 'index_examples'

  include_examples 'show_examples'
end
