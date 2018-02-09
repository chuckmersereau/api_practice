require 'rails_helper'

RSpec.describe Api::V2::Reports::SalaryCurrencyDonationsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:resource) do
    Reports::SalaryCurrencyDonations.new(account_list: account_list)
  end

  let(:parent_param) do
    {
      filter: {
        account_list_id: account_list.id
      }
    }
  end

  let(:given_reference_key) { 'donor_infos' }

  include_examples 'show_examples', except: [:sparse_fieldsets]
end
