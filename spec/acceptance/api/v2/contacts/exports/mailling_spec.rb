require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Exports > Mailing' do
  include_context :json_headers
  documentation_scope = :contacts_api_exports

  let(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists.first, addresses: [build(:address)]) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/exports/mailing.csv' do
      parameter 'filter[account_list_id]',     'Account List ID', type: 'String'
      parameter 'filter[ids]',                 'Contact IDs',     type: 'Array[String]'

      example 'Export [GET] [CSV]', document: documentation_scope do
        explanation 'List of Contacts rendered in CSV format with Mailing specific attributes'

        do_request
        expect(response_status).to eq 200
        expect(response_body).to include(contact.name)
        expect(response_body).to include(contact.csv_street)
        expect(response_headers['Content-Type']).to eq('text/csv')
      end
    end
  end
end
