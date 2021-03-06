require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'People > Merges > Bulk' do
  include_context :json_headers
  documentation_scope = :people_api_merges

  let!(:account_list)    { user.account_lists.order(:created_at).first }
  let!(:contact)         { create(:contact, account_list: account_list) }
  let!(:person_one)      { create(:person, contacts: [contact]) }
  let!(:person_two)      { create(:person, contacts: [contact]) }
  let!(:resource_type)   { 'people' }
  let!(:user)            { create(:user_with_account) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/contacts/people/merges/bulk' do
      with_options scope: [:data, :attributes] do
        parameter 'winner_id', 'The ID of the person that should win the merge'
        parameter 'loser_id', 'The ID of the person that should lose the merge'
      end

      example 'Merge People [BULK POST]', document: documentation_scope do
        explanation 'Bulk merge People with the given IDs'
        do_request data: [{ data: { attributes: { winner_id: person_one.id, loser_id: person_two.id } } }]
        expect(response_status).to eq(200)
        expect(json_response.size).to eq(1)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([person_one.id])
      end
    end
  end
end
