require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'People' do
  include_context :json_headers
  documentation_scope = :entities_people

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
      employer
      first_name
      gender
      last_name
      legal_first_name
      marital_status
      middle_name
      occupation
      optout_enewsletter
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

  documentation_scope = :entities_people

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people' do
      example 'List people', document: documentation_scope do
        explanation 'List of People associated to the Contact'
        do_request
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/contacts/:contact_id/people/:id' do
      with_options scope: :data do
        with_options scope: :attributes do
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
          response_field 'suffix',             'Suffix',                       type: 'String'
          response_field 'title',              'Title',                        type: 'String'
          response_field 'updated_at',         'Updated At',                   type: 'String'
          response_field 'updated_in_db_at',   'Updated In Db At',             type: 'String'
        end

        with_options scope: :relationships do
          response_field 'email_addresses',   'Email Addresses',  type: 'Object'
          response_field 'facebook_accounts', 'Facebook Account', type: 'Object'
          response_field 'phone_numbers',     'Phone Number',     type: 'Object'
        end
      end

      example 'Retrieve a person', document: documentation_scope do
        explanation 'The Contact\'s Person with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/contacts/:contact_id/people' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name', type: 'String'
        end
        parameter 'anniversary_day',                                          'Anniversary Day',                                                                  type: 'Number'
        parameter 'anniversary_month',                                        'Anniversary Month',                                                                type: 'Number'
        parameter 'anniversary_year',                                         'Anniversary Year',                                                                 type: 'Number'
        parameter 'birthday_day',                                             'Birthday Day',                                                                     type: 'Number'
        parameter 'birthday_month',                                           'Birthday Month',                                                                   type: 'Number'
        parameter 'birthday_year',                                            'Birthday Year',                                                                    type: 'Number'
        parameter 'deceased',                                                 'Deceased',                                                                         type: 'Boolean'
        parameter 'email_address[email]',                                     'Email Address',                                                                    type: 'String'
        parameter 'employer',                                                 'Employer',                                                                         type: 'String'
        parameter 'employer',                                                 'Employer',                                                                         type: 'String'
        parameter 'gender',                                                   'Gender',                                                                           type: 'String'
        parameter 'last_name',                                                'Last Name',                                                                        type: 'String'
        parameter 'legal_first_name',                                         'Legal First Name',                                                                 type: 'String'
        parameter 'legal_first_name',                                         'Legal First Name',                                                                 type: 'String'
        parameter 'marital_status',                                           'Marital Status',                                                                   type: 'String'
        parameter 'middle_name',                                              'Middle Name',                                                                      type: 'String'
        parameter 'occupation',                                               'Occupation',                                                                       type: 'String'
        parameter 'occupation',                                               'Occupation',                                                                       type: 'String'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter',                                                               type: 'Boolean'
        parameter 'optout_enewsletter',                                       'Optout of Enewsletter or not',                                                     type: 'Boolean'
        parameter 'phone_number[number]',                                     'Phone Number',                                                                     type: 'String'
        parameter 'profession',                                               'Profession',                                                                       type: 'String'
        parameter 'suffix',                                                   'Suffix',                                                                           type: 'String'
        parameter 'title',                                                    'Title',                                                                            type: 'String'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer',                      type: 'Number'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer',                                    type: 'String'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer',                                 type: 'Boolean'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer',          type: 'String'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer',                                  type: 'String'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer',                type: 'Number'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer',    type: 'String'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer',                 type: 'String'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer',                       type: 'String'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer',                   type: 'Number'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer',       type: 'String'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer',                                   type: 'String'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer',                       type: 'Number'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer',                                  type: 'String'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer',           type: 'String'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer',                                  type: 'String'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer',                                           type: 'String'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer',                                   type: 'Boolean'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer',                            type: 'Number'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer',                type: 'String'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer',                                    type: 'String'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer',                                          type: 'String'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer',                                        type: 'Boolean'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer',                    type: 'Number'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer',        type: 'String'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer',                            type: 'String'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer',                            type: 'Number'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer',                type: 'String'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer',                                        type: 'Boolean'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer',                                            type: 'String'
      end

      example 'Create a person', document: documentation_scope do
        explanation 'Create a Person associated with the Contact'
        do_request data: form_data
        expect(resource_object['first_name']).to(be_present) && eq(new_resource['first_name'])
        expect(response_status).to eq(201)
      end
    end

    put '/api/v2/contacts/:contact_id/people/:id' do
      with_options scope: [:data, :attributes] do
        with_options required: true do
          parameter 'first_name', 'First Name', type: 'String'
        end
        parameter 'anniversary_day',                                          'Anniversary Day',                                                                  type: 'Number'
        parameter 'anniversary_month',                                        'Anniversary Month',                                                                type: 'Number'
        parameter 'anniversary_year',                                         'Anniversary Year',                                                                 type: 'Number'
        parameter 'birthday_day',                                             'Birthday Day',                                                                     type: 'Number'
        parameter 'birthday_month',                                           'Birthday Month',                                                                   type: 'Number'
        parameter 'birthday_year',                                            'Birthday Year',                                                                    type: 'Number'
        parameter 'deceased',                                                 'Deceased',                                                                         type: 'Boolean'
        parameter 'employer',                                                 'Employer',                                                                         type: 'String'
        parameter 'gender',                                                   'Gender',                                                                           type: 'String'
        parameter 'last_name',                                                'Last Name',                                                                        type: 'String'
        parameter 'legal_first_name',                                         'Legal First Name',                                                                 type: 'String'
        parameter 'marital_status',                                           'Marital Status',                                                                   type: 'String'
        parameter 'middle_name',                                              'Middle Name',                                                                      type: 'String'
        parameter 'occupation',                                               'Occupation',                                                                       type: 'String'
        parameter 'optout_enewsletter',                                       'Optout Enewsletter',                                                               type: 'Boolean'
        parameter 'profession',                                               'Profession',                                                                       type: 'String'
        parameter 'suffix',                                                   'Suffix',                                                                           type: 'String'
        parameter 'title',                                                    'Title',                                                                            type: 'String'
        parameter 'email_address[email]',                                     'Email Address',                                                                    type: 'String'
        parameter 'phone_number[number]',                                     'Phone Number',                                                                     type: 'String'
        parameter 'email_addresses_attributes[:key][_destroy]',               'Destroy Email Address if set to 1, where :key is an integer',                      type: 'Number'
        parameter 'email_addresses_attributes[:key][email]',                  'Email Address Email, where :key is an integer',                                    type: 'String'
        parameter 'email_addresses_attributes[:key][historic]',               'Email Address Historic, where :key is an integer',                                 type: 'Boolean'
        parameter 'email_addresses_attributes[:key][id]',                     'Email Address ID, omit to create a new record, where :key is an integer',          type: 'String'
        parameter 'email_addresses_attributes[:key][primary]',                'Email Address Primary, where :key is an integer',                                  type: 'String'
        parameter 'family_relationships_attributes[:key][_destroy]',          'Destroy Family Relationship if set to 1, where :key is an integer',                type: 'Number'
        parameter 'family_relationships_attributes[:key][id]',                'Family Relationship ID, omit to create a new record, where :key is an integer',    type: 'String'
        parameter 'family_relationships_attributes[:key][related_person_id]', 'Family Relationship Related Persion ID, where :key is an integer',                 type: 'String'
        parameter 'family_relationships_attributes[:key][relationship]',      'Family Relationship Relationship, where :key is an integer',                       type: 'String'
        parameter 'linkedin_accounts_attributes[:key][_destroy]',             'Destroy LinkedIn Account if set to 1, where :key is an integer',                   type: 'Number'
        parameter 'linkedin_accounts_attributes[:key][id]',                   'LinkedIn Account ID, omit to create a new record, where :key is an integer',       type: 'String'
        parameter 'linkedin_accounts_attributes[:key][url]',                  'LinkedIn Account URL, where :key is an integer',                                   type: 'String'
        parameter 'phone_numbers_attributes[:key][_destroy]',                 'Destroy Phone Number if set to 1, where :key is an integer',                       type: 'Number'
        parameter 'phone_numbers_attributes[:key][historic]',                 'Phone Number Historic, where :key is an integer',                                  type: 'String'
        parameter 'phone_numbers_attributes[:key][id]',                       'Phone Number ID, omit to create a new record, where :key is an integer',           type: 'String'
        parameter 'phone_numbers_attributes[:key][location]',                 'Phone Number Location, where :key is an integer',                                  type: 'String'
        parameter 'phone_numbers_attributes[:key][number]',                   'Phone Number, where :key is an integer',                                           type: 'String'
        parameter 'phone_numbers_attributes[:key][primary]',                  'Phone Number Primary, where :key is an integer',                                   type: 'Boolean'
        parameter 'pictures_attributes[:key][_destroy]',                      'Destroy Picture if set to 1, where :key is an integer',                            type: 'Number'
        parameter 'pictures_attributes[:key][id]',                            'Picture ID, omit to create a new record, where :key is an integer',                type: 'String'
        parameter 'pictures_attributes[:key][image_cache]',                   'Picture Image Cache, where :key is an integer',                                    type: 'String'
        parameter 'pictures_attributes[:key][image]',                         'Picture Image, where :key is an integer',                                          type: 'String'
        parameter 'pictures_attributes[:key][primary]',                       'Picture Primary, where :key is an integer',                                        type: 'Boolean'
        parameter 'twitter_accounts_attributes[:key][_destroy]',              'Destroy Twitter Account if set to 1, where :key is an integer',                    type: 'Number'
        parameter 'twitter_accounts_attributes[:key][id]',                    'Twitter Account ID, omit to create a new record, where :key is an integer',        type: 'String'
        parameter 'twitter_accounts_attributes[:key][screen_name]',           'Twitter Account Screen Name, where :key is an integer',                            type: 'String'
        parameter 'websites_attributes[:key][_destroy]',                      'Destroy Website if set to 1, where :key is an integer',                            type: 'Number'
        parameter 'websites_attributes[:key][id]',                            'Website ID, omit to create a new record, where :key is an integer',                type: 'String'
        parameter 'websites_attributes[:key][primary]',                       'Website Primary, where :key is an integer',                                        type: 'Boolean'
        parameter 'websites_attributes[:key][url]',                           'Website URL, where :key is an integer',                                            type: 'String'
      end

      example 'Update a person', document: documentation_scope do
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
      example 'Delete a person', document: documentation_scope do
        explanation 'Delete the Contact\'s Person with the given ID'
        do_request
        expect(response_status).to eq(204)
      end
    end
  end
end
