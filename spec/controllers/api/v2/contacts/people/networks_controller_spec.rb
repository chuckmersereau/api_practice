require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::NetworksController, type: :controller do
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:person) { create(:person) }
  let!(:person2) { create(:person) }

  before do
    contact.people << person
  end

  context 'Facebook' do
    let(:factory_type) { :facebook_account }
    let!(:resource) { create(factory_type, person: person) }
    let(:id) { resource.id }
    let(:parent_param) { { contact_id: contact.id, person_id: person.id, filters: { network: 'facebook' } } }
    let(:unpermitted_attributes) { nil }
    let(:correct_attributes) { attributes_for(factory_type, person: person2, first_name: 'Albert') }
    let(:incorrect_attributes) { attributes_for(factory_type, person: nil, username: nil) }
    include_examples 'show_examples'
    include_examples 'create_examples'
    include_examples 'update_examples'
    include_examples 'destroy_examples'
  end

  context 'Linkedin' do
    let(:factory_type) { :linkedin_account }
    let!(:resource) { create(factory_type, person: person) }
    let(:id) { resource.id }
    let(:parent_param) { { contact_id: contact.id, person_id: person.id, filters: { network: 'linkedin' } } }
    let(:unpermitted_attributes) { nil }
    let(:correct_attributes) { attributes_for(factory_type, person: person2, first_name: 'Albert') }
    let(:incorrect_attributes) { attributes_for(factory_type, person: nil, public_url: nil) }
    include_examples 'show_examples'
    include_examples 'create_examples'
    include_examples 'update_examples'
    include_examples 'destroy_examples'
  end

  context 'Twitter' do
    let(:factory_type) { :twitter_account }
    let!(:resource) { create(factory_type, person: person) }
    let(:id) { resource.id }
    let(:parent_param) { { contact_id: contact.id, person_id: person.id, filters: { network: 'twitter' } } }
    let(:unpermitted_attributes) { nil }
    let(:correct_attributes) { attributes_for(factory_type, person_id: person2.id) }
    let(:incorrect_attributes) { attributes_for(factory_type, screen_name: nil) }
    include_examples 'show_examples'
    include_examples 'create_examples'
    include_examples 'update_examples'
    include_examples 'destroy_examples'
  end

  context 'Website' do
    let(:factory_type) { :website }
    let!(:resource) { create(factory_type, person: person) }
    let(:id) { resource.id }
    let(:parent_param) { { contact_id: contact.id, person_id: person.id, filters: { network: 'website' } } }
    let(:unpermitted_attributes) { nil }
    let(:correct_attributes) { attributes_for(factory_type, person: person2, website: 'http://www.example192.com') }
    let(:incorrect_attributes) { attributes_for(factory_type, person: nil, url: nil) }
    include_examples 'show_examples'
    include_examples 'create_examples'
    include_examples 'update_examples'
    include_examples 'destroy_examples'
  end

  context 'List networks' do
    let!(:facebook_accounts) { create_list(:facebook_account, 2, person: person) }
    let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
    let!(:twitter_accounts) { create_list(:twitter_account, 3, person: person) }
    let!(:websites) { create_list(:website, 3, person: person) }
    let(:params) { { contact_id: contact.id, person_id: person.id, filters: { networks: 'website,twitter,facebook, linkedin' } } }

    describe '#index' do
      it 'shows resources to users that are signed in' do
        api_login(user)
        get :index, params
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].count).to eq(10)
        expect(response.body).to include(facebook_accounts.first.first_name)
        expect(response.body).to include(linkedin_accounts.first.public_url)
        expect(response.body).to include(twitter_accounts.first.screen_name)
        expect(response.body).to include(websites.first.url)
      end

      it 'does not shows resources to users that are not signed in' do
        get :index, params
        expect(response.status).to eq(401)
      end

      it 'does not show resources for users that do not own the resources' do
        api_login(create(:user))
        get :index, params
        expect(response.status).to eq(403)
      end
    end
  end
end
