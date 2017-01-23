require 'spec_helper'

describe Api::V2::Contacts::BulkController, type: :controller do
  let!(:account_list)              { user.account_lists.first }
  let!(:account_list_id)           { account_list.uuid }
  let!(:correct_attributes)        { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let!(:factory_type)              { :contact }
  let!(:id)                        { resource.uuid }
  let!(:incorrect_attributes)      { attributes_for(:contact, name: nil, account_list_id: account_list_id) }
  let!(:incorrect_reference_value) { resource.send(reference_key) }
  let!(:given_reference_key)       { :name }
  let!(:given_reference_value)     { correct_attributes[:name] }
  let!(:resource)                  { create(:contact_with_person, account_list: account_list) }
  let!(:second_resource)           { create(:contact, account_list: account_list) }
  let!(:third_resource)            { create(:contact, account_list: account_list) }
  let!(:user)                      { create(:user_with_account) }

  include_examples 'bulk_update_examples'

  include_examples 'bulk_destroy_examples'
end
