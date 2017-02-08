require 'rails_helper'

describe Api::V2::Tasks::BulkController, type: :controller do
  let!(:account_list)              { user.account_lists.first }
  let!(:account_list_id)           { account_list.uuid }
  let!(:correct_attributes)        { attributes_for(:task, subject: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let!(:factory_type)              { :task }
  let!(:id)                        { resource.uuid }
  let!(:incorrect_attributes)      { attributes_for(:task, subject: nil, account_list_id: account_list_id) }
  let!(:incorrect_reference_value) { resource.send(reference_key) }
  let!(:given_reference_key)       { :subject }
  let!(:given_reference_value)     { correct_attributes[:subject] }
  let!(:resource)                  { create(:task, account_list: account_list) }
  let!(:second_resource)           { create(:task, account_list: account_list) }
  let!(:third_resource)            { create(:task, account_list: account_list) }
  let!(:user)                      { create(:user_with_account) }

  include_examples 'bulk_update_examples'

  include_examples 'bulk_destroy_examples'
end
