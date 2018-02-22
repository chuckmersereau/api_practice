require 'rails_helper'

RSpec.describe Api::V2::Contacts::People::LinkedinAccountsController, type: :controller do
  let(:factory_type) { :linkedin_account }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }
  let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
  let(:linkedin_account) { linkedin_accounts.first }
  let(:resource) { linkedin_account }
  let(:id) { linkedin_account.id }
  let(:parent_param) { { contact_id: contact.id, person_id: person.id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:linkedin_account, first_name: 'Albert').except(:person_id) }
  let(:incorrect_attributes) { { public_url: nil } }
  let(:incorrect_relationships) { {} }

  let(:given_reference_key) { :public_url }

  before do
    contact.people << person
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
