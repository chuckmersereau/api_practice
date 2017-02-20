require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Exports' do
  include_context :json_headers
  documentation_scope = :contacts_api_exports

  let!(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists.first) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/exports.csv' do
      parameter 'filter[account_list_id]',     'Account List ID', 'Type' => 'String'
      parameter 'filter[ids]',                 'Contact IDs',     'Type' => 'Array[String]'

      example 'Export [GET] [CSV]', document: documentation_scope do
        explanation 'List of Contacts rendered in CSV format'

        do_request
        expect(response_status).to eq 200
        expect(response_body).to include(contact.name)
        expect(response_headers['Content-Type']).to eq('text/csv')
      end
    end

    get '/api/v2/contacts/exports.xlsx' do
      parameter 'filter[account_list_id]',     'Account List ID', 'Type' => 'String'
      parameter 'filter[ids]',                 'Contact IDs',     'Type' => 'Array[String]'

      example 'Export [GET] [XLSX]', document: false do
        explanation 'List of Contacts rendered in XLSX format'
        do_request
        expect(response_status).to eq 200
        expect(response_headers['Content-Type']).to eq('application/xlsx')
      end
    end
  end
end
