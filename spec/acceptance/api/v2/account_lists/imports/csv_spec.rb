require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Imports > from CSV' do
  include_context :multipart_form_data_headers
  include ActionDispatch::TestProcess
  documentation_scope = :account_lists_api_imports

  before { stub_smarty_streets }

  let(:resource_type) { 'imports' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let!(:imports) do
    create_list(:csv_import, 2, account_list: account_list, user: user,
                                in_preview: true,
                                file_headers_mappings: file_headers_mappings,
                                file_constants_mappings: file_constants_mappings)
  end
  let!(:import) { imports.first }

  let(:id) { import.id }

  let(:file_headers_mappings) do
    {
      'city' => 'city',
      'pledge_amount' => 'amount',
      'pledge_frequency' => 'frequency',
      'contact_name' => 'fname',
      'country' => 'country',
      'email_1' => 'email_address',
      'envelope_greeting' => 'envelope_greeting',
      'first_name' => 'fname',
      'greeting' => 'greeting',
      'last_name' => 'lname',
      'newsletter' => 'newsletter',
      'notes' => 'extra_notes',
      'phone_1' => 'phone',
      'spouse_email' => 'spouse_email_address',
      'spouse_first_name' => 'spouse_fname',
      'spouse_last_name' => 'spouse_lname',
      'spouse_phone' => 'spouse_phone_number',
      'state' => 'province',
      'status' => 'status',
      'street' => 'street',
      'zip' => 'zip_code'
    }
  end

  let(:file_constants_mappings) do
    {
      'status' => [
        { 'id' => 'Partner - Financial', 'values' => ['Praying and giving'] }
      ],
      'pledge_frequency' => [
        { 'id' => '1.0', 'values' => ['Monthly'] }
      ],
      'newsletter' => [
        { 'id' => 'Both', 'values' => ['Both'] }
      ]
    }
  end

  let(:new_import) do
    attrs = {
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/sample_csv_with_custom_headers.csv')),
      file_headers_mappings: file_headers_mappings,
      file_constants_mappings: file_constants_mappings
    }

    build(:csv_import)
      .attributes
      .reject { |attr| attr.to_s.end_with?('_id') }
      .tap { |attributes| attributes.delete('id') }
      .tap { |attributes| attributes.delete('in_preview') }
      .tap { |attributes| attributes['updated_in_db_at'] = import.updated_at }
      .tap { |attributes| attributes['updated_at'] = import.updated_at }
      .tap { |attributes| attributes['created_at'] = import.created_at }
      .merge(attrs)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      },
      user: {
        data: {
          type: 'users',
          id: user.id
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      account_list_id
      created_at
      file_constants
      file_constants_mappings
      file_headers
      file_headers_mappings
      file_url
      group_tags
      groups
      import_by_group
      in_preview
      override
      source
      tag_list
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      user
      sample_contacts
    )
  end

  let(:form_data) { build_data(new_import, relationships: relationships) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/imports/csv' do
      parameter 'account_list_id', 'Account List ID', type: 'String', required: true

      example 'CSV Import [LIST]', document: documentation_scope do
        explanation 'List of CSV Imports associated with the Account List'
        do_request
        check_collection_resource(2, ['relationships'])
        expect(response_status).to eq 200
        expect(resource_data.first['attributes']['file_url']).to be_present
        expect(resource_data.first['attributes']['source']).to eq 'csv'
      end
    end

    get '/api/v2/account_lists/:account_list_id/imports/csv/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',         'Account List ID',                                                            type: 'Number'
        response_field 'created_at',              'Created At',                                                                 type: 'String'
        response_field 'file_url',                'A URL to download the file',                                                 type: 'String'
        response_field 'file_headers_mappings',   "An Object that maps attributes in MPDX (keys) to headers in the users's " \
                                                  'CSV file (values); The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported attributes',       type: 'Object'
        response_field 'file_headers',            'A list of all the headers in the uploaded CSV file',                         type: 'Object'
        response_field 'file_constants',          "File constants are intended to help map values in the user's CSV file to " \
                                                  'MPDX constants. This is a list of unique values for each column in the ' \
                                                  "CSV. Columns are ignored if they obviously aren't constants " \
                                                  '(like "name"), so not every column is returned. At most ' \
                                                  "#{CsvFileConstantsReader::MAX_MAPPINGS_PER_HEADER} results will be returned " \
                                                  'for each column.', type: 'Object'
        response_field 'file_constants_mappings', "An Object that maps constants in MPDX to constants in the users's " \
                                                  'CSV file; The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported constants',        type: 'Object'
        response_field 'group_tags',              'Group Tags',                                                                 type: 'String'
        response_field 'groups',                  'Groups',                                                                     type: 'Array[String]'
        response_field 'import_by_group',         'Import by Group',                                                            type: 'String'
        response_field 'in_preview',              "The Import will not be performed while it's in preview; Defaults to true",   type: 'Boolean'
        response_field 'override',                'Override',                                                                   type: 'Boolean'
        response_field 'source',                  'Source; Defaults to "csv"',                                                  type: 'String'
        response_field 'tag_list',                'Comma delimited list of tags to apply to the imported Contacts',             type: 'String'
        response_field 'updated_at',              'Updated At',                                                                 type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',                                                           type: 'String'
      end

      example 'CSV Import [GET]', document: documentation_scope do
        explanation 'The Import with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
        expect(resource_data['attributes']['file_url']).to be_present
        expect(resource_data['attributes']['source']).to eq 'csv'
        expect(resource_data['attributes']['file_constants_mappings']).to eq(file_constants_mappings)
        expect(resource_data['attributes']['file_headers_mappings']).to eq(file_headers_mappings)
      end
    end

    put '/api/v2/account_lists/:account_list_id/imports/csv/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'file',                    'The CSV file uploaded as form-data', type: 'String'
        parameter 'file_headers_mappings',   "An Object that maps attributes in MPDX (keys) to headers in the users's " \
                                             'CSV file (values); The client must supply this before import can begin; ' \
                                             'Please see the Constants endpoint for a list of supported attributes', type: 'Object'
        parameter 'file_constants_mappings', "An Object that maps constants in MPDX (keys) to constants in the users's " \
                                             'CSV file (values); The client must supply this before import can begin; ' \
                                             'Please see the Constants endpoint for a list of supported constants',        type: 'Object'
        parameter 'groups',                  'Groups',                                                                     type: 'String'
        parameter 'group_tags',              'Group Tags',                                                                 type: 'String'
        parameter 'import_by_group',         'Import by Group',                                                            type: 'String'
        parameter 'override',                'Override',                                                                   type: 'Boolean'
        parameter 'source_account_id',       'Source Account ID',                                                          type: 'String'
        parameter 'tag_list',                'Comma delimited list of Tags',                                               type: 'String'
        parameter 'user_id',                 'User ID',                                                                    type: 'String'
      end

      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',         'Account List ID',                                                            type: 'Number'
        response_field 'created_at',              'Created At',                                                                 type: 'String'
        response_field 'file_url',                'A URL to download the file',                                                 type: 'String'
        response_field 'file_headers_mappings',   "An Object that maps attributes in MPDX (keys) to headers in the users's " \
                                                  'CSV file (values); The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported attributes',       type: 'Object'
        response_field 'file_headers',            'A list of all the headers in the uploaded CSV file',                         type: 'Object'
        response_field 'file_constants',          "File constants are intended to help map values in the user's CSV file to " \
                                                  'MPDX constants. This is a list of unique values for each column in the ' \
                                                  "CSV. Columns are ignored if they obviously aren't constants " \
                                                  '(like "name"), so not every column is returned. At most ' \
                                                  "#{CsvFileConstantsReader::MAX_MAPPINGS_PER_HEADER} results will be returned " \
                                                  'for each column.', type: 'Object'
        response_field 'file_constants_mappings', "An Object that maps constants in MPDX to constants in the users's " \
                                                  'CSV file; The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported constants',        type: 'Object'
        response_field 'group_tags',              'Group Tags',                                                                 type: 'String'
        response_field 'groups',                  'Groups',                                                                     type: 'Array[String]'
        response_field 'import_by_group',         'Import by Group',                                                            type: 'String'
        response_field 'in_preview',              "The Import will not be performed while it's in preview; Defaults to true",   type: 'Boolean'
        response_field 'override',                'Override',                                                                   type: 'Boolean'
        response_field 'source',                  'Source; Defaults to "csv"',                                                  type: 'String'
        response_field 'tag_list',                'Comma delimited list of Tags to apply to the imported Contacts',             type: 'String'
        response_field 'updated_at',              'Updated At',                                                                 type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',                                                           type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'user', 'User that the Import belongs to', type: 'Object'
        response_field 'sample_contacts', 'The sample Contacts are a preview of what the imported Contacts would look like. ' \
                                          'It uses the first few rows of the CSV file to generate the samples.', type: 'Object'
      end

      example 'CSV Import [UPDATE]', document: documentation_scope do
        explanation 'Update a CSV Import associated with the Account List. For more details regarding the CSV Import see the description on the create request.'
        do_request data: form_data
        check_resource(['relationships'])
        expect(response_status).to eq(200), invalid_status_detail
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['file_url']).to be_present
        expect(resource_data['attributes']['source']).to eq 'csv'
        expect(resource_data['attributes']['in_preview']).to eq true
        expect(resource_data['attributes']['file_constants_mappings']).to eq(file_constants_mappings)
        expect(resource_data['attributes']['file_headers_mappings']).to eq(file_headers_mappings)
        expect(resource_data['relationships']['sample_contacts']['data'].size).to eq(3)
      end
    end

    post '/api/v2/account_lists/:account_list_id/imports/csv' do
      with_options scope: [:data, :attributes] do
        parameter 'file',                    'The CSV file uploaded as form-data', type: 'String'
        parameter 'file_headers_mappings',   "An Object that maps attributes in MPDX (keys) to headers in the users's " \
                                             'CSV file (values); The client must supply this before import can begin; ' \
                                             'Please see the Constants endpoint for a list of supported attributes', type: 'Object'
        parameter 'file_constants_mappings', "An Object that maps constants in MPDX (keys) to constants in the users's " \
                                             'CSV file (values); The client must supply this before import can begin; ' \
                                             'Please see the Constants endpoint for a list of supported constants',        type: 'Object'
        parameter 'groups',                  'Groups',                                                                     type: 'String'
        parameter 'group_tags',              'Group Tags',                                                                 type: 'String'
        parameter 'import_by_group',         'Import by Group',                                                            type: 'String'
        parameter 'override',                'Override',                                                                   type: 'Boolean'
        parameter 'source_account_id',       'Source Account ID',                                                          type: 'String'
        parameter 'tag_list',                'Comma delimited list of Tags',                                               type: 'String'
        parameter 'user_id',                 'User ID',                                                                    type: 'String'
      end

      with_options scope: [:data, :attributes] do
        response_field 'account_list_id',         'Account List ID',                                                            type: 'Number'
        response_field 'created_at',              'Created At',                                                                 type: 'String'
        response_field 'file_url',                'A URL to download the file',                                                 type: 'String'
        response_field 'file_headers_mappings',   "An Object that maps attributes in MPDX (keys) to headers in the users's " \
                                                  'CSV file (values); The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported attributes',       type: 'Object'
        response_field 'file_headers',            'A list of all the headers in the uploaded CSV file',                         type: 'Object'
        response_field 'file_constants',          "File constants are intended to help map values in the user's CSV file to " \
                                                  'MPDX constants. This is a list of unique values for each column in the ' \
                                                  "CSV. Columns are ignored if they obviously aren't constants " \
                                                  '(like "name"), so not every column is returned. At most ' \
                                                  "#{CsvFileConstantsReader::MAX_MAPPINGS_PER_HEADER} results will be returned " \
                                                  'for each column.', type: 'Object'
        response_field 'file_constants_mappings', "An Object that maps constants in MPDX (keys) to constants in the users's " \
                                                  'CSV file (values); The client must supply this before import can begin; ' \
                                                  'Please see the Constants endpoint for a list of supported constants',        type: 'Object'
        response_field 'group_tags',              'Group Tags',                                                                 type: 'String'
        response_field 'groups',                  'Groups',                                                                     type: 'Array[String]'
        response_field 'import_by_group',         'Import by Group',                                                            type: 'String'
        response_field 'in_preview',              "The Import will not be performed while it's in preview; Defaults to true",   type: 'Boolean'
        response_field 'override',                'Override',                                                                   type: 'Boolean'
        response_field 'source',                  'Source; Defaults to "csv"',                                                  type: 'String'
        response_field 'tag_list',                'Comma delimited list of Tags to apply to the imported Contacts',             type: 'String'
        response_field 'updated_at',              'Updated At',                                                                 type: 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',                                                           type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'user', 'User that the Import belongs to', type: 'Object'
        response_field 'sample_contacts', 'The sample Contacts are a preview of what the imported Contacts would look like. ' \
                                          'It uses the first few rows of the CSV file to generate the samples.', type: 'Object'
      end

      example 'CSV Import [CREATE]', document: documentation_scope do
        explanation '<p>Creates a new CSV Import associated with the Account List. This endpoint expects a CSV file to be uploaded using Content-Type ' \
                    '"multipart/form-data", this makes the endpoint unique in that it does not expect only JSON content. ' \
                    'Unless otherwise specified, the Import will be created with "in_preview" set to true. </p>' \
                    '<p>A CSV Import is expected to take multiple steps to setup: </p>' \
                    '<p>1. The first step is to create a new Import via a POST request, ' \
                    'the client can upload the CSV file in the POST request using "multipart/form-data". ' \
                    'If the file upload is successful then the file_headers and file_constants will be returned to the client in the response. </p>' \
                    '<p>2. In the second step the client is expected to update (via PUT) the file_headers_mappings ' \
                    "according to the user's desire (based on the file_headers). This step could take several attempts. </p>" \
                    '<p>3. In the third step the client is expected to update (via PUT) the file_constants_mappings ' \
                    "according to the user's desire (based on the file_constants). This step could take several attempts. </p>" \
                    '<p>4. The fourth step is to show a sample of the import to the user. The sample_contacts relationship should be used. ' \
                    '<p>5. The fifth step is to start the import. The client is expected to update (via PUT) the "in_preview" attribute to "false", ' \
                    'which will trigger the import to begin (as a background job). If the mappings are incorrect or incomplete, ' \
                    'or the record is otherwise invalid, then the import will not begin and an error object will be returned instead. </p>'
        do_request data: form_data
        check_resource(['relationships'])
        expect(response_status).to eq(201), invalid_status_detail
        expect(response_headers['Content-Type']).to eq 'application/vnd.api+json; charset=utf-8'
        expect(resource_data['id']).to be_present
        expect(resource_data['attributes']['file_url']).to be_present
        expect(resource_data['attributes']['source']).to eq 'csv'
        expect(resource_data['attributes']['in_preview']).to eq true
        expect(resource_data['relationships']['sample_contacts']['data'].size).to eq(3)
      end
    end
  end
end
