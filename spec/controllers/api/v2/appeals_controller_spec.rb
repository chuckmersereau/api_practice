require 'spec_helper'

describe Api::V2::AppealsController, type: :controller do
  let(:resource_type) { 'appeal' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:appeal) { create(:appeal, account_list_id: account_list_id) }
  let(:id) { appeal.id }

  let(:resource) { appeal }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:appeal, name: 'Appeal 2', account_list_id: account_list_id) }
  let(:unpermitted_attributes) { attributes_for(:appeal, name: 'Appeal 3', account_list_id: create(:account_list).id) }
  let(:incorrect_attributes) { attributes_for(:appeal, account_list_id: nil) }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
