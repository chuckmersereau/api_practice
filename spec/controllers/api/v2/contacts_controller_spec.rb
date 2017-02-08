require 'rails_helper'

describe Api::V2::ContactsController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:contact) { create(:contact_with_person, account_list: account_list) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let(:id) { contact.uuid }

  let!(:resource) { contact }
  let(:second_resource) { second_contact }

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).uuid
        }
      }
    }
  end

  let(:correct_attributes) do
    {
      name: 'Test Name'
    }
  end

  let(:incorrect_attributes) do
    {
      name: nil
    }
  end

  let(:reference_key) { :name }
  let(:reference_value) { correct_attributes[:name] }
  let(:incorrect_reference_value) { resource.send(reference_key) }
  let(:incorrect_attributes) { attributes_for(:contact, name: nil) }
  let(:sorting_param) { :name }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  describe 'filtering' do
    before { api_login(user) }

    (Contact::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore) + Contact::Filterer::FILTERS_TO_HIDE.collect(&:underscore)).each do |filter|
      context "#{filter} filter" do
        it 'filters results' do
          get :index, filter: { filter => '' }
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq('')
        end
      end
    end

    context 'account_list_id filter' do
      let!(:user) { create(:user_with_account) }
      let!(:account_list_two) { create(:account_list) }
      let!(:contact_two) { create(:contact, account_list: account_list_two) }
      before { user.account_lists << account_list_two }
      it 'filters results' do
        get :index, filter: { account_list_id: account_list_two.uuid }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end
end
