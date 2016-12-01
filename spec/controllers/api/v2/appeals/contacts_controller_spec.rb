require 'spec_helper'

describe Api::V2::Appeals::ContactsController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.id }
  let!(:contact) { create(:contact, account_list_id: account_list_id, appeals: [appeal]) }
  let!(:second_contact) { create(:contact, account_list_id: account_list_id, appeals: [appeal]) }
  let(:id) { contact.id }

  let(:resource) { contact }
  let(:parent_param) { { appeal_id: appeal_id, filters: { account_list_id: account_list.id, excluded: 0 } } }
  let(:correct_attributes) { attributes_for(:contact, name: 'Doe, Frank') }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'destroy_examples'
end
