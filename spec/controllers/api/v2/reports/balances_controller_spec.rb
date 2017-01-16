require 'spec_helper'

RSpec.describe Api::V2::Reports::BalancesController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    Reports::Balances.new(account_list: account_list)
  end

  let!(:designation_account) { create(:designation_account) }

  before do
    account_list.designation_accounts << designation_account
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.uuid
      }
    }
  end

  let(:correct_attributes) { {} }
  include_examples 'show_examples'
end
