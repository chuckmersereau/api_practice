require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tools Analytics' do
  include_context :json_headers
  documentation_scope = :tools_api_analytics

  let(:resource_type) { 'tools_analytics' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      counts_by_type
      created_at
      updated_at
      updated_in_db_at
    )
  end

  let(:counts_by_type) { json_response['data']['attributes']['counts_by_type'] }

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/tools/analytics' do
      parameter 'filter[account_list_id]', 'Filter by Account List Id', type: 'String'

      with_options scope: [:data, :attributes] do
        response_field 'counts_by_type', 'Gives the number of contacts, addresses, '\
                                         'phone numbers and email addresses that '\
                                         'need to be fixed by the user. It also gives '\
                                         'a count of the number of duplicated contacts '\
                                         'and people associated to him/her.',  type: 'Object'

        response_field 'created_at',     'Time when analytics were observed',  type: 'String'
        response_field 'updated_at',     'Time when analytics were observed',  type: 'String'
      end

      example 'Analytics [GET]', document: documentation_scope do
        explanation 'Analytics with information allowing the user to decide if he should use any of the tools.'
        do_request
        expect(response_status).to eq 200
        check_resource
        expect(counts_by_type.first['id']).to be_present
        expect(counts_by_type.first['counts'].first).to be_a Hash
      end
    end
  end
end
