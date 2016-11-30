require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Facebook Accounts' do
  let(:resource_type) { 'person-facebook-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let(:contact_id) { contact.id }
  let!(:person) { create(:person) }
  let(:person_id) { person.id }
  let!(:facebook_accounts) { create_list(:facebook_account, 2, person: person) }
  let(:facebook_account) { facebook_accounts.first }
  let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
  let(:linkedin_account) { linkedin_accounts.first }
  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account) { twitter_accounts.first }
  let!(:websites) { create_list(:website, 2, person: person) }
  let(:website) { websites.first }
  let(:facebook_id) { facebook_account.id }
  let(:linkedin_id) { linkedin_account.id }
  let(:twitter_id) { twitter_account.id }
  let(:website_id) { website.id }
  let(:new_facebook_account) { build(:facebook_account).attributes }
  let(:facebook_form_data) { build_data(new_facebook_account) }
  let(:new_linkedin_account) { build(:linkedin_account).attributes }
  let(:linkedin_form_data) { build_data(new_linkedin_account) }
  let(:new_twitter_account) { build(:twitter_account).attributes }
  let(:twitter_form_data) { build_data(new_twitter_account) }
  let(:new_website) { build(:website).attributes }
  let(:website_form_data) { build_data(new_website) }
  let(:expected_facebook_attribute_keys) do
    %w(created-at
       first-name
       last-name
       remote-id
       updated-at
       username)
  end
  let(:expected_linkedin_attribute_keys) do
    %w(created-at
       authenticated
       first-name
       last-name
       public-url
       remote-id
       updated-at)
  end
  let(:expected_twitter_attribute_keys) do
    %w(created-at
       primary
       remote-id
       screen-name
       updated-at)
  end
  let(:expected_website_attribute_keys) do
    %w(created-at
       primary
       updated-at
       url)
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/networks' do
      networks = 'facebook,linkedin,twitter,website'
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      parameter 'networks',                     'Networks', required: true, scope: :filters
      response_field 'data',                    'Data', 'Type' => 'Array[Object]'
      example 'list facebook accounts of person' do
        do_request filters: { networks: networks }
        check_collection_resource(8)
        expect(resource_data[0]['attributes'].keys).to match_array expected_facebook_attribute_keys
        expect(resource_data[2]['attributes'].keys).to match_array expected_linkedin_attribute_keys
        expect(resource_data[4]['attributes'].keys).to match_array expected_twitter_attribute_keys
        expect(resource_data[6]['attributes'].keys).to match_array expected_website_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/networks/:facebook_id' do
      network = 'facebook'
      parameter 'network', 'Network must be: facebook', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'first-name',              'First Name', 'Type' => 'String'
        response_field 'last-name',               'Last name', 'Type' => 'Number'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
        response_field 'username',                'Username', 'Type' => 'String'
      end
      example 'get network [facebook account]' do
        do_request filters: { network: network }
        expect(resource_object.keys).to match_array expected_facebook_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/networks/:linkedin_id' do
      network = 'linkedin'
      parameter 'network', 'Network must be: linkedin', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'first-name',              'First Name', 'Type' => 'String'
        response_field 'last-name',               'Last name', 'Type' => 'Number'
        response_field 'public-url',              'Public URL', 'Type' => 'String'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
      end
      example 'get network [linkedin account]' do
        do_request filters: { network: network }
        expect(resource_object.keys).to match_array expected_linkedin_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/networks/:twitter_id' do
      network = 'twitter'
      parameter 'network', 'Network must be: twitter', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'primary',                 'Primary', 'Type' => 'Boolean'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'screen-name',             'Screen Name', 'Type' => 'String'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
      end
      example 'get network [twitter account]' do
        do_request filters: { network: network }
        expect(resource_object.keys).to match_array expected_twitter_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/networks/:website_id' do
      network = 'website'
      parameter 'network', 'Network must be: website', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'primary',                 'Primary', 'Type' => 'Boolean'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
        response_field 'url',                     'Url', 'Type' => 'String'
      end
      example 'get network [website account]' do
        do_request filters: { network: network }
        expect(resource_object.keys).to match_array expected_website_attribute_keys
        expect(status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/networks' do
      network = 'facebook'
      parameter 'network', 'Network must be: facebook', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        parameter 'first-name',                   'First Name'
        parameter 'last-name',                    'Last Name'
        parameter 'remote-id',                    'Remote ID'
        parameter 'username',                     'Username'
      end
      example 'creates network [facebook account]' do
        do_request data: facebook_form_data, filters: { network: network }
        expect(status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/networks' do
      network = 'linkedin'
      parameter 'network', 'Network must be: linkedin', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        parameter 'first-name',                   'First Name'
        parameter 'last-name',                    'Last Name'
        parameter 'public-url',                   'Public URL'
        parameter 'remote-id',                    'Remote ID'
      end
      example 'creates network [linkedin account]' do
        do_request data: linkedin_form_data, filters: { network: network }
        expect(status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/networks' do
      network = 'twitter'
      parameter 'network', 'Network must be: twitter', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'remote-id',                    'Remote ID'
        parameter 'screen-name',                  'Screen Name'
      end
      example 'creates network [twitter account]' do
        do_request data: twitter_form_data, filters: { network: network }
        expect(status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/networks' do
      network = 'website'
      parameter 'network', 'Network must be: website', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'url',                          'Url'
      end
      example 'creates network [website account]' do
        do_request data: website_form_data, filters: { network: network }
        expect(status).to eq 200
      end
    end
    put '/api/v2/contacts/:contact_id/people/:person_id/networks/:facebook_id' do
      network = 'facebook'
      parameter 'network', 'Network must be: website', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        parameter 'first-name',                   'First Name'
        parameter 'last-name',                    'Last Name'
        parameter 'remote-id',                    'Remote ID'
        parameter 'username',                     'Username'
      end
      example 'update facebook account' do
        do_request data: facebook_form_data, filters: { network: network }
        expect(status).to eq 200
      end
    end
    delete '/api/v2/contacts/:contact_id/people/:person_id/networks/:facebook_id' do
      network = 'website'
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      parameter 'network',                      'Network', required: true, scope: :filters
      example 'deletes network' do
        do_request filters: { network: network }
        expect(status).to eq 200
      end
    end
  end
end
