require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'People' do
  include_context :json_headers

  let!(:user)         { create(:user_with_full_account) }
  let(:resource_type) { 'people' }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }

  let!(:resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let(:id)        { resource.uuid }

  let(:new_resource) do
    build(:person, first_name: 'Mpdx').attributes
                                      .reject { |key| key.to_s.end_with?('_id') }
                                      .merge(updated_in_db_at: contact.updated_at)
  end

  let(:relationship_person) { create(:person) }

  let(:form_data) { build_data(new_resource) }

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
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      email_addresses
      facebook_accounts
      family_relationships
      linkedin_accounts
      master_person
      phone_numbers
      twitter_accounts
      websites
    )
  end

  let(:nested_family_relationship_data) do
    {
      included: [
        {
          attributes: {
            relationship: 'Nephew'
          },
          relationships: {
            related_person: {
              data: {
                type: 'people',
                id: relationship_person.uuid
              }
            }
          },
          type: 'family_relationships',
          id: 'ce1e9746-2b34-4d3d-9357-292a950e681a'
        }
      ],
      data: {
        relationships: {
          linkedin_accounts: {
            data: nil
          },
          facebook_accounts: {
            data: nil
          },
          family_relationships: {
            data: [
              {
                type: 'family_relationships',
                id: 'ce1e9746-2b34-4d3d-9357-292a950e681a'
              }
            ]
          },
          websites: {
            data: nil
          },
          email_addresses: {
            data: nil
          }
        },
        attributes: {
          birthday_year: nil,
          first_name: 'new',
          last_name: 'person',
          middle_name: nil,
          suffix: nil,
          title: nil,
          gender: 'female',
          created_at: resource.created_at,
          marital_status: 'Married',
          updated_at: resource.updated_at,
          anniversary_day: nil,
          anniversary_month: nil,
          birthday_day: nil,
          updated_in_db_at: resource.updated_at,
          anniversary_year: nil,
          birthday_month: nil,
          deceased: false
        },
        type: 'people',
        id: resource.uuid
      }
    }
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people' do
      example 'Person [LIST]', document: :entities do
        explanation 'List of People associated to the Contact'
        do_request
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
          response_field 'updated_in_db_at',  'Updated In Db At',  'Type' => 'String'
        end

        with_options scope: :relationships do
          response_field 'email_addresses',   'Email Addresses',  'Type' => 'Object'
          response_field 'facebook_accounts', 'Facebook Account', 'Type' => 'Object'
          response_field 'phone_numbers',     'Phone Number',     'Type' => 'Object'
        end
      end

      example 'Person [GET]', document: :entities do
        explanation 'The Contact\'s Person with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/contacts/:contact_id/people' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name', 'Type' => 'String'
        end
        parameter 'anniversary_day',                                          'Anniversary Day',                                                                  'Type' => 'Number'
        parameter 'anniversary_month',                                        'Anniversary Month',                                                                'Type' => 'Number'
        parameter 'anniversary_year',                                         'Anniversary Year',                                                                 'Type' => 'Number'
        parameter 'birthday_day',                                             'Birthday Day',                                                                     'Type' => 'Number'
        parameter 'birthday_month',                                           'Birthday Month',                                                                   'Type' => 'Number'
        parameter 'birthday_year',                                            'Birthday Year',                                                                    'Type' => 'Number'
        parameter 'deceased',                                                 'Deceased',                                                                         'Type' => 'Boolean'
        parameter 'employer',                                                 'Employer',                                                                         'Type' => 'String'
        parameter 'gender',                                                   'Gender',                                                                           'Type' => 'String'
        parameter 'last_name',                                                'Last Name',                                                                        'Type' => 'String'
        parameter 'legal_first_name',                                         'Legal First Name',                                                                 'Type' => 'String'
        parameter 'marital_status',                                           'Marital Status',                                                                   'Type' => 'String'
        parameter 'middle_name',                                              'Middle Name',                                                                      'Type' => 'String'
        parameter 'occupation',                                               'Occupation',                                                                       'Type' => 'String'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter',                                                               'Type' => 'Boolean'
        parameter 'profession',                                               'Profession',                                                                       'Type' => 'String'
        parameter 'suffix',                                                   'Suffix',                                                                           'Type' => 'String'
        parameter 'title',                                                    'Title',                                                                            'Type' => 'String'
        parameter 'email_address[email]',                                     'Email Address',                                                                    'Type' => 'String'
        parameter 'phone_number[number]',                                     'Phone Number',                                                                     'Type' => 'String'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer',                      'Type' => 'Number'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer',                                    'Type' => 'String'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer',                                 'Type' => 'Boolean'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer',          'Type' => 'String'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer',                                  'Type' => 'String'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer',                'Type' => 'Number'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer',    'Type' => 'String'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer',                 'Type' => 'String'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer',                       'Type' => 'String'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer',                   'Type' => 'Number'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer',       'Type' => 'String'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer',                                   'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer',                       'Type' => 'Number'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer',                                  'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer',           'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer',                                  'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer',                                           'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer',                                   'Type' => 'Boolean'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer',                            'Type' => 'Number'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer',                'Type' => 'String'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer',                                    'Type' => 'String'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer',                                          'Type' => 'String'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer',                                        'Type' => 'Boolean'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer',                    'Type' => 'Number'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer',        'Type' => 'String'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer',                            'Type' => 'String'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer',                            'Type' => 'Number'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer',                'Type' => 'String'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer',                                        'Type' => 'Boolean'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer',                                            'Type' => 'String'
      end

      example 'Person [CREATE]', document: :entities do
        explanation 'Create a Person associated with the Contact'
        do_request data: form_data
        expect(resource_object['first_name']).to(be_present) && eq(new_resource['first_name'])
        expect(response_status).to eq(201)
      end
    end

    put '/api/v2/contacts/:contact_id/people/:id' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name', 'Type' => 'String'
        end
        parameter 'anniversary_day',                                          'Anniversary Day',                                                                  'Type' => 'Number'
        parameter 'anniversary_month',                                        'Anniversary Month',                                                                'Type' => 'Number'
        parameter 'anniversary_year',                                         'Anniversary Year',                                                                 'Type' => 'Number'
        parameter 'birthday_day',                                             'Birthday Day',                                                                     'Type' => 'Number'
        parameter 'birthday_month',                                           'Birthday Month',                                                                   'Type' => 'Number'
        parameter 'birthday_year',                                            'Birthday Year',                                                                    'Type' => 'Number'
        parameter 'deceased',                                                 'Deceased',                                                                         'Type' => 'Boolean'
        parameter 'employer',                                                 'Employer',                                                                         'Type' => 'String'
        parameter 'gender',                                                   'Gender',                                                                           'Type' => 'String'
        parameter 'last_name',                                                'Last Name',                                                                        'Type' => 'String'
        parameter 'legal_first_name',                                         'Legal First Name',                                                                 'Type' => 'String'
        parameter 'marital_status',                                           'Marital Status',                                                                   'Type' => 'String'
        parameter 'middle_name',                                              'Middle Name',                                                                      'Type' => 'String'
        parameter 'occupation',                                               'Occupation',                                                                       'Type' => 'String'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter',                                                               'Type' => 'Boolean'
        parameter 'profession',                                               'Profession',                                                                       'Type' => 'String'
        parameter 'suffix',                                                   'Suffix',                                                                           'Type' => 'String'
        parameter 'title',                                                    'Title',                                                                            'Type' => 'String'
        parameter 'email_address[email]',                                     'Email Address',                                                                    'Type' => 'String'
        parameter 'phone_number[number]',                                     'Phone Number',                                                                     'Type' => 'String'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer',                      'Type' => 'Number'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer',                                    'Type' => 'String'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer',                                 'Type' => 'Boolean'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer',          'Type' => 'String'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer',                                  'Type' => 'String'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer',                'Type' => 'Number'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer',    'Type' => 'String'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer',                 'Type' => 'String'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer',                       'Type' => 'String'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer',                   'Type' => 'Number'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer',       'Type' => 'String'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer',                                   'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer',                       'Type' => 'Number'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer',                                  'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer',           'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer',                                  'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer',                                           'Type' => 'String'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer',                                   'Type' => 'Boolean'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer',                            'Type' => 'Number'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer',                'Type' => 'String'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer',                                    'Type' => 'String'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer',                                          'Type' => 'String'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer',                                        'Type' => 'Boolean'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer',                    'Type' => 'Number'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer',        'Type' => 'String'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer',                            'Type' => 'String'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer',                            'Type' => 'Number'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer',                'Type' => 'String'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer',                                        'Type' => 'Boolean'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer',                                            'Type' => 'String'
      end

      example 'Person [UPDATE]', document: :entities do
        explanation 'Update the Contact\'s Person with the given ID'
        do_request data: form_data
        expect(resource_object['first_name']).to(be_present) && eq(new_resource['first_name'])
        expect(response_status).to eq(200)
      end
    end

    put '/api/v2/contacts/:contact_id/people/:id' do
      example 'Person Nested Family Relationships', document: :private do
        explanation 'Create a family relationship for the person'
        expect(resource.family_relationships).to be_empty

        do_request nested_family_relationship_data

        expect(response_status).to eq(200), invalid_status_detail
        expect(resource.reload.family_relationships).not_to be_empty
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:id' do
      example 'Person [DELETE]', document: :entities do
        explanation 'Delete the Contact\'s Person with the given ID'
        do_request
        expect(response_status).to eq(204)
      end
    end
  end
end
