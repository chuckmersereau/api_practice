require 'rails_helper'

RSpec.describe Api::V2::Contacts::People::TwitterAccountsController, type: :controller do
  let(:factory_type) { :twitter_account }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account) { twitter_accounts.first }
  let(:resource) { twitter_account }
  let(:id) { twitter_account.id }
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
