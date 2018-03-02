require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  include_context :json_headers
  documentation_scope = :entities_user

  let(:resource_type) { 'users' }
  let(:user) { create(:user_with_full_account) }

  let(:new_user_attributes) do
    attributes_for(:user_with_full_account)
      .except(:access_token, :email, :locale, :time_zone)
      .merge(updated_in_db_at: user.updated_at).except(:email)
  end

  let(:form_data)           { build_data(new_user_attributes) }

  let(:resource_attributes) do
    %w(
      anniversary_day
      anniversary_month
      anniversary_year
      avatar
      birthday_day
      birthday_month
      birthday_year
      deceased
      employer
      first_name
      gender
      last_name
      legal_first_name
      marital_status
      middle_name
      occupation
      optout_enewsletter
      parent_contacts
      preferences
      title
      suffix
      created_at
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_lists
      email_addresses
      master_person
      facebook_accounts
      family_relationships
      linkedin_accounts
      phone_numbers
      twitter_accounts
      websites
    )
  end

  context 'authorized user' do
    before { api_login(user) }
    around(:example) do |example|
      travel_to Time.zone.local(1951, 1, 24, 1, 1, 0), &example
    end

    get '/api/v2/user' do
      response_field 'attributes',    'User object',                                type: 'Object'
      response_field 'id',            'User ID',                                    type: 'Number'
      response_field 'relationships', 'list of relationships related to that User', type: 'Array[Object]'
      response_field 'type',          'Will be User',                               type: 'String'

      with_options scope: [:data, :attributes] do
        response_field 'anniversary_day',    'Anniversary Day',              type: 'Number'
        response_field 'anniversary_month',  'Anniversary Month',            type: 'Number'
        response_field 'anniversary_year',   'Anniversary Year',             type: 'Number'
        response_field 'avatar',             'Avatar',                       type: 'String'
        response_field 'birthday_day',       'Birthday Day',                 type: 'Number'
        response_field 'birthday_month',     'Birthday Month',               type: 'Number'
        response_field 'birthday_year',      'Birthday Year',                type: 'Number'
        response_field 'created_at',         'Created At',                   type: 'String'
        response_field 'deceased',           'Deceased',                     type: 'Boolean'
        response_field 'employer',           'Employer',                     type: 'String'
        response_field 'first_name',         'First Name',                   type: 'String'
        response_field 'gender',             'Gender',                       type: 'String'
        response_field 'last_name',          'Last Name',                    type: 'String'
        response_field 'legal_first_name',   'Legal First Name',             type: 'String'
        response_field 'marital_status',     'Marital Status',               type: 'String'
        response_field 'master_person_id',   'Master Person ID',             type: 'Number'
        response_field 'middle_name',        'Middle Name',                  type: 'String'
        response_field 'occupation',         'Occupation',                   type: 'String'
        response_field 'optout_enewsletter', 'Optout of Enewsletter or not', type: 'Boolean'
        response_field 'parent_contacts',    'Array of Parent Contact Ids',  type: 'Array'
        response_field 'suffix',             'Suffix',                       type: 'String'
        response_field 'title',              'Title',                        type: 'String'
        response_field 'preferences',        'User preferences',             type: 'Object'
        response_field 'updated_at',         'Updated At',                   type: 'String'
        response_field 'updated_in_db_at',   'Updated In Db At',             type: 'String'
      end

      example 'Retrieve the current user', document: documentation_scope do
        explanation 'The current_user'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name',       'User first name', type: 'String', required: true
        parameter 'last_name',        'User last name',  type: 'String'

        with_options scope: :preferences do
          parameter 'contacts_filter',       'Contacts Filter',        type: 'String'
          parameter 'contacts_view_options', 'Contacts View Options',  type: 'String'
          parameter 'default_account_list',  'Default Account List',   type: 'String'
          parameter 'locale',                'User Locale',            type: 'String'
          parameter 'setup',                 'User Preferences Setup', type: 'String'
          parameter 'tab_orders',            'Tab Orders',             type: 'String'
          parameter 'tasks_filter',          'Tasks Filter',           type: 'String'
          parameter 'time_zone',             'User Time Zone',         type: 'String'
        end
      end

      example 'Update the current user', document: documentation_scope do
        explanation 'Update the current_user'
        do_request data: form_data
        expect(resource_object['first_name']).to eq new_user_attributes[:first_name]
        expect(response_status).to eq 200
      end
    end
  end
end
