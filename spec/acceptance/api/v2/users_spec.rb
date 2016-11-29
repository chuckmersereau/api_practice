require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  let(:resource_type) { 'users' }
  let(:user) { create(:user_with_full_account) }
  let(:user_attributes) { attributes_for :user_with_full_account }
  let(:account_list) { user.account_lists.first }
  let(:new_user) { attributes_for :user }
  let(:form_data) { build_data(new_user) }
  let(:expected_attribute_keys) do
    %w(created-at
       first-name
       last-name
       master-person-id
       preferences
       updated-at)
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/user' do
      response_field 'attributes',        'user object', 'Type' => 'Object'
      response_field 'id',                'user id', 'Type' => 'Integer'
      response_field 'relationships',     'list of relationships related to that user object', 'Type' => 'Array'
      response_field 'type',              'Will be User', 'Type' => 'String'
      example_request 'get user' do
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user' do
      with_options scope: [:data, :attributes] do
        parameter 'anniversary_day',      'user anniversary day'
        parameter 'anniversary_year',     'user anniversary year'
        parameter 'birthday_day',         'user birthday day'
        parameter 'birthday_month',       'user birthday month'
        parameter 'birthday_year',        'user birthday year'
        parameter 'deceased',             'user deceased'
        parameter 'employer',             'user employer'
        parameter 'first_name',           'user first name', required: true
        parameter 'last_name',            'user last name', required: true
        parameter 'legal_first_name',     'user legal first name'
        parameter 'marital_status',       'user marital status'
        parameter 'middle_name',          'user middle name'
        parameter 'occupation',           'user occupation'
        parameter 'preferences',          'user preferences', required: true
        parameter 'profession',           'user profession'
        parameter 'suffix',               'user suffix'
        parameter 'title',                'user title'
      end

      example 'update user' do
        do_request data: form_data
        expect(resource_object['first-name']).to eq new_user[:first_name]
        expect(response_status).to eq 200
      end
    end
  end
end
