require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::TwitterAccountsController, type: :controller do
  let(:factory_type) { :twitter_account }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:resource) { create(:twitter_account, person: person) }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id, person_id: person.id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:twitter_account, person_id: person2.id) }
  let(:incorrect_attributes) { attributes_for(:twitter_account, screen_name: nil) }

  before do
    contact.people << person
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end