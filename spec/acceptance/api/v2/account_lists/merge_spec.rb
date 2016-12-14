require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Merge' do
  include_context :json_headers

  let(:resource_type) { 'merge' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:account_list2)   { create(:account_list) }
  let(:account_list2_id) { account_list2.uuid }

  before do
    account_list2.users << user
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/merge' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'ID (id of account list to be merged)', required: true, scope: [:data, :attributes]

      example 'Account List [MERGE]', document: :account_lists do
        explanation 'Merges the contacts of the given Account List into this Account List'
        do_request data: build_data(id: account_list2_id)
        expect(response_status).to eq 201
      end
    end
  end
end
