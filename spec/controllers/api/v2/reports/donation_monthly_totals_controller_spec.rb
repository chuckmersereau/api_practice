require 'rails_helper'

RSpec.describe Api::V2::Reports::DonationMonthlyTotalsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    Reports::DonationMonthlyTotals.new(account_list: account_list,
                                       start_date: 4.months.ago,
                                       end_date: 2.months.ago)
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.uuid,
        month_range: "#{4.months.ago.utc.iso8601}...#{2.months.ago.utc.iso8601}"
      }
    }
  end

  let(:given_reference_key) { 'donation_totals_by_month' }

  include_examples 'show_examples', except: [:includes, :sparse_fieldsets]
end
