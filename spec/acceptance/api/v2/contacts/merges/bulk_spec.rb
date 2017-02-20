require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Merges > Bulk' do
  include_context :json_headers
  documentation_scope = :contacts_api_merges

  let!(:account_list)    { user.account_lists.first }
  let!(:contact_one)     { create(:contact, account_list: account_list) }
  let!(:contact_two)     { create(:contact, account_list: account_list) }
  let!(:resource_type)   { 'contacts' }
  let!(:user)            { create(:user_with_account) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/contacts/merges/bulk' do
      with_options scope: [:data, :attributes] do
        parameter 'winner_id', 'The ID of the contact that should win the merge'
        parameter 'loser_id', 'The ID of the contact that should lose the merge'
      end

      example 'Merge Contacts [BULK POST]', document: documentation_scope do
        explanation 'Bulk merge Contacts with the given IDs'
        do_request data: [{ data: { attributes: { winner_id: contact_one.uuid, loser_id: contact_two.uuid } } }]
        expect(response_status).to eq(200)
        expect(json_response.size).to eq(1)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([contact_one.uuid])
      end
    end
  end
end
