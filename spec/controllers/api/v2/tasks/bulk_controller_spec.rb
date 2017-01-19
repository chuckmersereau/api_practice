require 'spec_helper'

describe Api::V2::Tasks::BulkController, type: :controller do
  let(:factory_type) { :task }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:task) { create(:task, account_list: account_list) }
  let!(:second_task) { create(:task, account_list: account_list) }

  let(:id) { task.uuid }
  let(:resource) { task }
  let(:second_resource) { second_task }

  let(:correct_attributes) { attributes_for(:task, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let(:incorrect_attributes) { attributes_for(:task, name: nil, account_list_id: account_list_id) }

  let(:reference_key) { :name }
  let(:reference_value) { correct_attributes[:name] }
  let(:incorrect_reference_value) { resource.send(reference_key) }

  include_examples 'bulk_update_examples'
end
