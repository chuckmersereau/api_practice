require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::LinkedinAccountsController, type: :controller do
  let(:factory_type) { :linkedin_account }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
  let(:linkedin_account) { linkedin_accounts.first }
  let(:resource) { linkedin_account }
  let(:id) { linkedin_account.uuid }
  let(:parent_param) { { contact_id: contact.uuid, person_id: person.uuid } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:linkedin_account, person: person2, first_name: 'Albert') }
  let(:incorrect_attributes) { attributes_for(:linkedin_account, person: nil, public_url: nil) }

  before do
    contact.people << person
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
