require 'spec_helper'
require 'support/shared_controller_examples'

describe Api::V2::ContactsController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:contact) { create(:contact, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let(:id) { contact.id }

  let!(:resource) { contact }
  let(:correct_attributes) { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id) }
  let(:reference_key) { :name }
  let(:reference_value) { correct_attributes[:name] }
  let(:incorrect_reference_value) { resource.send(reference_key) }
  let(:incorrect_attributes) { attributes_for(:contact, name: nil, account_list_id: account_list_id) }
  let(:unpermitted_attributes) { nil }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
