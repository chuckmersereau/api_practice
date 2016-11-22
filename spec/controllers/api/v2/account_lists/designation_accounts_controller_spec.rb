require 'spec_helper'

describe Api::V2::AccountLists::DesignationAccountsController, type: :controller do
  let(:factory_type) { :designation_account }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:designation_account) { create(:designation_account) }
  let(:id) { designation_account.id }

  before do
    account_list.designation_accounts << designation_account
  end

  let(:resource) { designation_account }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:designation_account) }

  include_examples 'index_examples'

  include_examples 'show_examples'
end
