require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  let(:resource_type) { 'users' }

  let(:user)            { create(:user_with_full_account) }
  let(:user_attributes) { attributes_for :user_with_full_account }
  let(:account_list)    { user.account_lists.first }

  let(:new_user)  { attributes_for :user }
  let(:form_data) { build_data(new_user) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      first_name
      last_name
      preferences
      updated_at
    )
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/user' do
      response_field 'attributes',    'User object',                                'Type' => 'Object'
      response_field 'id',            'User ID',                                    'Type' => 'Number'
      response_field 'relationships', 'list of relationships related to that User', 'Type' => 'Array[Object]'
      response_field 'type',          'Will be User',                               'Type' => 'String'

      example_request 'get user' do
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user' do
      with_options scope: [:data, :attributes] do
        parameter 'anniversary_day',      'User anniversary day'
        parameter 'anniversary_year',     'User anniversary year'
        parameter 'birthday_day',         'User birthday day'
        parameter 'birthday_month',       'User birthday month'
        parameter 'birthday_year',        'User birthday year'
        parameter 'deceased',             'User deceased'
        parameter 'employer',             'User employer'
        parameter 'first_name',           'User first name', required: true
        parameter 'last_name',            'User last name', required: true
        parameter 'legal_first_name',     'User legal first name'
        parameter 'marital_status',       'User marital status'
        parameter 'middle_name',          'User middle name'
        parameter 'occupation',           'User occupation'
        parameter 'preferences',          'User preferences', required: true
        parameter 'profession',           'User profession'
        parameter 'suffix',               'User suffix'
        parameter 'title',                'User title'
      end

      example 'update user' do
        do_request data: form_data
        expect(resource_object['first_name']).to eq new_user[:first_name]
        expect(response_status).to eq 200
      end
    end
  end
end
