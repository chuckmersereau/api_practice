require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts Bulk' do
  include_context :json_headers

  let!(:account_list)    { user.account_lists.first }
  let!(:contact_one)     { create(:contact, account_list: account_list) }
  let!(:contact_two)     { create(:contact, account_list: account_list) }
  let!(:resource_type)   { 'contacts' }
  let!(:user)            { create(:user_with_account) }

  context 'authorized user' do
    before { api_login(user) }

    delete '/api/v2/contacts/bulk' do
      with_options scope: :data do
        parameter :id, 'Each member of the array must contain the id of the contact being deleted'
      end

      example 'Contact [DELETE] [BULK]', document: :entities do
        explanation 'Bulk delete Contacts with the given IDs'
        do_request data: [{ data: { id: contact_one.uuid } }, { data: { id: contact_two.uuid } }]
        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([contact_one.uuid, contact_two.uuid])
      end
    end
  end
end
