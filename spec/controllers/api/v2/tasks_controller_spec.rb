require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::TasksController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :task }
  let!(:resource) { create(:task, account_list: account_list) }
  let!(:second_resource) { create(:task, account_list: account_list) }
  let(:id) { resource.uuid }
  let(:correct_attributes) { { subject: 'test subject', start_at: Time.now, account_list_id: account_list.uuid } }
  let(:unpermitted_attributes) { { subject: 'test subject', start_at: Time.now, account_list_id: create(:account_list).uuid } }
  let(:incorrect_attributes) { { subject: nil, account_list_id: account_list.uuid } }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
