require 'spec_helper'

describe Api::V2::Appeals::ContactsController, type: :controller do
  let(:resource_type) { 'contact' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.id }
  let!(:contact) { create(:contact, account_list_id: account_list_id) }
  let(:id) { contact.id }

  before do
    appeal.contacts << contact
  end

  let(:resource) { contact }
  # let(:parent_param) { { filter: { account_list_id: account_list.id, appeal_id: appeal_id } } }
  # let(:parent_param) { { account_list_id: account_list_id, appeal_id: appeal_id } } # good one
  # let(:parent_param) { { appeal_id: appeal_id } }
  let(:parent_param) { { filter: { account_list_id: account_list.id, appeal_id: appeal_id } } }
  let(:correct_attributes) { attributes_for(:contact, name: 'Doe, Frank') }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'destroy_examples'
end
