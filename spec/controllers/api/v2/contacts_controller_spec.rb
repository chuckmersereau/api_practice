require 'spec_helper'
require 'support/shared_controller_examples'

describe Api::V2::ContactsController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:contact) { create(:contact_with_person, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let(:id) { contact.uuid }

  let!(:resource) { contact }
  let(:correct_attributes) { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
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

  describe 'filtering' do
    before { api_login(user) }

    Contact::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).each do |filter|
      it "accepts displayable filter #{filter}" do
        get :index, filters: { filter => '' }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['meta']['filters'][filter]).to eq('')
      end
    end

    Contact::Filterer::FILTERS_TO_HIDE.collect(&:underscore).each do |filter|
      it "does not accept hidden filter #{filter}" do
        get :index, filters: { filter => '' }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['meta']['filters']).to be_blank
      end
    end
  end
end
