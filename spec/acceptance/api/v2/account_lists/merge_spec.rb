require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Merges' do
  include_context :json_headers
  documentation_scope = :account_list_api_merges

  let(:resource_type) { 'merge' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let!(:account_list_id) { account_list.id }

  let!(:account_list2)   { create(:account_list) }
  let!(:account_list2_id) { account_list2.id }

  let(:form_data) do
    {
      data: {
        type: 'merge',
        relationships: {
          account_list_to_merge: {
            data: {
              type: 'account_lists',
              id: account_list2_id
            }
          }
        }
      }
    }
  end

  before do
    account_list2.users << user
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/merge' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'ID (id of account list to be merged)', required: true, scope: [:data, :attributes]

      example 'Account List [MERGE]', document: documentation_scope do
        explanation 'Merges the contacts of the given Account List into this Account List'
        do_request form_data
        expect(response_status).to eq(201), invalid_status_detail
      end
    end
  end
end
