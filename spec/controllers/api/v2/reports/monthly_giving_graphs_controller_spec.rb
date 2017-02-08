require 'rails_helper'

RSpec.describe Api::V2::Reports::MonthlyGivingGraphsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    Reports::MonthlyGivingGraph.new(account_list: account_list, locale: 'en')
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.uuid
      }
    }
  end

  let(:correct_attributes) { {} }

  include_examples 'show_examples', except: [:sparse_fieldsets]
end
