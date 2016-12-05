require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'People' do
  let!(:resource)     { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let!(:user)         { create(:user_with_full_account) }
  let(:contact)       { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id)    { contact.id }
  let(:form_data)     { build_data(new_resource) }
  let(:id)            { resource.id }
  let(:new_resource)  { build(:person, first_name: 'Mpdx').attributes }
  let(:resource_type) { 'people' }
  let(:resource_attributes) do
    %w(
      anniversary_day
      anniversary_month
      anniversary_year
      avatar
      birthday_day
      birthday_month
      birthday_year
      created_at
      deceased
      first_name
      gender
      last_name
      marital_status
      middle_name
      suffix
      title
      updated_at)
  end
  let(:resource_associations) do
    %w(
      email_addresses
      facebook_accounts
      master_person
      phone_numbers
    )
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people' do
      example_request 'get people' do
        explanation('List of people associated to the contact')
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/contacts/:contact_id/people/:id' do
      with_options scope: :data do
        with_options scope: :attributes do
          response_field 'anniversary_day',   'Anniversary Day',   'Type' => 'Number'
          response_field 'anniversary_month', 'Anniversary Month', 'Type' => 'Number'
          response_field 'anniversary_year',  'Anniversary Year',  'Type' => 'Number'
          response_field 'avatar',            'Avatar',            'Type' => 'String'
          response_field 'birthday_day',      'Birthday Day',      'Type' => 'Number'
          response_field 'birthday_month',    'Birthday Month',    'Type' => 'Number'
          response_field 'birthday_year',     'Birthday Year',     'Type' => 'Number'
          response_field 'created_at',        'Created At',        'Type' => 'String'
          response_field 'deceased',          'Deceased',          'Type' => 'Boolean'
          response_field 'first_name',        'First Name',        'Type' => 'String'
          response_field 'gender',            'Gender',            'Type' => 'String'
          response_field 'last_name',         'Last Name',         'Type' => 'String'
          response_field 'marital_status',    'Marital Status',    'Type' => 'String'
          response_field 'master_person_id',  'Master Person ID',  'Type' => 'Number'
          response_field 'middle_name',       'Middle Name',       'Type' => 'String'
          response_field 'suffix',            'Suffix',            'Type' => 'String'
          response_field 'title',             'Title',             'Type' => 'String'
          response_field 'updated_at',        'Updated At',        'Type' => 'String'
        end
        with_options scope: :relationships do
          response_field 'email_addresses',   'Email Addresses',  'Type' => 'Object'
          response_field 'facebook_accounts', 'Facebook Account', 'Type' => 'Object'
          response_field 'phone_numbers',     'Phone Number',     'Type' => 'Object'
        end
      end

      example_request 'get person' do
        check_resource(['relationships'])
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/contacts/:contact_id/people' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name'
        end
        parameter 'anniversary_day',                                          'Anniversary Day'
        parameter 'anniversary_month',                                        'Anniversary Month'
        parameter 'anniversary_year',                                         'Anniversary Year'
        parameter 'birthday_day',                                             'Birthday Day'
        parameter 'birthday_month',                                           'Birthday Month'
        parameter 'birthday_year',                                            'Birthday Year'
        parameter 'deceased',                                                 'Deceased'
        parameter 'employer',                                                 'Employer'
        parameter 'gender',                                                   'Gender'
        parameter 'last_name',                                                'Last Name'
        parameter 'legal_first_name',                                         'Legal First Name'
        parameter 'marital_status',                                           'Marital Status'
        parameter 'middle_name',                                              'Middle Name'
        parameter 'occupation',                                               'Occupation'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter'
        parameter 'profession',                                               'Profession'
        parameter 'suffix',                                                   'Suffix'
        parameter 'title',                                                    'Title'
        parameter 'email_address[email]',                                     'Email Address'
        parameter 'phone_number[number]',                                     'Phone Number'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer'
      end

      example 'create person' do
        do_request data: form_data
        expect(resource_object['first_name']).to(be_present) && eq(new_resource['first_name'])
        expect(response_status).to eq(200)
      end
    end

    put '/api/v2/contacts/:contact_id/people/:id' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name'
        end
        parameter 'anniversary_day',                                          'Anniversary Day'
        parameter 'anniversary_month',                                        'Anniversary Month'
        parameter 'anniversary_year',                                         'Anniversary Year'
        parameter 'birthday_day',                                             'Birthday Day'
        parameter 'birthday_month',                                           'Birthday Month'
        parameter 'birthday_year',                                            'Birthday Year'
        parameter 'deceased',                                                 'Deceased'
        parameter 'employer',                                                 'Employer'
        parameter 'gender',                                                   'Gender'
        parameter 'last_name',                                                'Last Name'
        parameter 'legal_first_name',                                         'Legal First Name'
        parameter 'marital_status',                                           'Marital Status'
        parameter 'middle_name',                                              'Middle Name'
        parameter 'occupation',                                               'Occupation'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter'
        parameter 'profession',                                               'Profession'
        parameter 'suffix',                                                   'Suffix'
        parameter 'title',                                                    'Title'
        parameter 'email_address[email]',                                     'Email Address'
        parameter 'phone_number[number]',                                     'Phone Number'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer'
      end

      example 'update person' do
        do_request data: form_data
        expect(resource_object['first_name']).to(be_present) && eq(new_resource['first_name'])
        expect(response_status).to eq(200)
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:id' do
      example_request 'delete person' do
        expect(response_status).to eq(200)
      end
    end
  end
end
