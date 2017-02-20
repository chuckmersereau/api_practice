require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account List ChalkLine Mail' do
  include_context :json_headers
  documentation_scope = :account_lists_api_chalkline_mail

  let(:resource_type) { 'chalkline_mails' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/chalkline_mail' do
      example 'ChalkLine Mail [CREATE]', document: documentation_scope do
        explanation 'Enqueues a job that will send ChalkLine Mail for this Account List'
        travel_to Time.current do
          do_request account_list_id: account_list_id, data: { type: 'chalkline_mails' }
          expect(response_status).to eq 201
          expect(json_response).to eq('data' => {
                                        'id' => '',
                                        'type' => 'chalkline_mails',
                                        'attributes' => {
                                          'created_at' => Time.current.utc.iso8601,
                                          'updated_at' => nil,
                                          'updated_in_db_at' => nil
                                        }
                                      }
                                     )
        end
      end
    end
  end
end
