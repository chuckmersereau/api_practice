require 'rails_helper'

RSpec.describe Api::V2::Contacts::People::FacebookAccountsController, type: :controller do
  let(:factory_type) { :facebook_account }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:facebook_accounts) { create_list(:facebook_account, 2, person: person) }
  let(:facebook_account) { facebook_accounts.first }
  let(:resource) { facebook_account }
  let(:id) { facebook_account.id }
  let(:parent_param) { { contact_id: contact.id, person_id: person.id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:facebook_account, first_name: 'Albert').except(:person_id) }
  let(:incorrect_attributes) { { username: nil } }

  before do
    contact.people << person
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
