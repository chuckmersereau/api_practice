require 'spec_helper'

RSpec.describe Api::V2::AccountLists::AnalyticsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    AccountList::Analytics.new(
      account_list: account_list,
      start_date: 1.week.ago,
      end_date: Time.current
    )
  end

  let(:parent_param) do
    {
      filter: {
        start_date: 1.week.ago.iso8601,
        end_date: Time.current.iso8601
      },
      account_list_id: account_list.uuid
    }
  end

  let(:given_reference_key) { 'appointments' }

  include_examples 'show_examples'
end
