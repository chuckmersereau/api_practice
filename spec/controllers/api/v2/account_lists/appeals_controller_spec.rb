require 'spec_helper'

describe Api::V2::AccountLists::AppealsController, type: :controller do
  let(:resource_type) { 'appeal' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  # let!(:contact) { create(:contact, account_list_id: account_list.id) }
  # let!(:donor_account) { create(:donor_account) }
  # let!(:designation_account) { create(:designation_account) }
  # let!(:donations) { create_list(:donation, 2, donor_account: donor_account, designation_account: designation_account, amount: 10.00) }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:id) { appeal.id }

  before do
  end

  let(:resource) { appeal }
  let(:parent_path) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:appeal) }
  let(:incorrect_attributes) { { account_list_id: nil } }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end