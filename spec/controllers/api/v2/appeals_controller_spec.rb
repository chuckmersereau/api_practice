require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::AppealsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :appeal }
  let!(:resource) { create(:appeal, account_list: account_list) }
  let(:id) { resource.id }
  let(:parent_param) { { filters: { account_list_id: account_list.id } } }
  let(:correct_attributes) { attributes_for(:appeal, name: 'Appeal 2', account_list_id: account_list.id) }
  let(:unpermitted_attributes) { attributes_for(:appeal, name: 'Appeal 3', account_list_id: create(:account_list).id) }
  let(:incorrect_attributes) { attributes_for(:appeal, account_list_id: account_list.id, name: nil) }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
