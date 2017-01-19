require 'spec_helper'

describe Api::V2::Contacts::BulkController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:contact) { create(:contact_with_person, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }

  let(:id) { contact.uuid }
  let(:resource) { contact }
  let(:second_resource) { second_contact }

  let(:correct_attributes) { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let(:incorrect_attributes) { attributes_for(:contact, name: nil, account_list_id: account_list_id) }

  let(:reference_key) { :name }
  let(:reference_value) { correct_attributes[:name] }
  let(:incorrect_reference_value) { resource.send(reference_key) }

  include_examples 'bulk_update_examples'
end
