require 'rails_helper'

RSpec.describe Api::V2::Reports::GoalProgressesController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:resource) do
    Reports::GoalProgress.new(account_list: account_list)
  end

  let!(:designation_account) { create(:designation_account) }

  before do
    account_list.designation_accounts << designation_account
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.id
      }
    }
  end

  let(:correct_attributes) { {} }

  include_examples 'show_examples', except: [:sparse_fieldsets]
end
