require 'rails_helper'

RSpec.describe Api::V2::Reports::DonationMonthlyTotalsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    Reports::DonationMonthlyTotals.new(account_list: account_list,
                                       start_date: DateTime.new(2017, 1, 3),
                                       end_date: DateTime.new(2017, 3, 3))
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.id,
        month_range: "#{DateTime.new(2017, 1, 3).utc.iso8601}...#{DateTime.new(2017, 3, 3).utc.iso8601}"
      }
    }
  end

  let(:given_reference_key) { 'donation_totals_by_month' }

  include_examples 'show_examples', except: [:includes, :sparse_fieldsets]
end
