require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Notification Preferences > Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:account_lists, :notification_preferences, :bulk])

  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let!(:resource_type)  { 'notification_preferences' }
  let!(:user)           { create(:user_with_account) }

  let(:bulk_create_form_data) do
    [{
      data: {
        type: resource_type,
        id: SecureRandom.uuid,
        attributes: {
          email: true,
          task: true
        },
        relationships: {
          notification_type: {
            data: {
              type: 'notification_types',
              id: create(:notification_type).id
            }
          }
        }
      }
    }]
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/account_lists/:account_list_id/notification_preferences/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_create, context: self)

      example doc_helper.title_for(:bulk_create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_create)
        do_request data: bulk_create_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['email']).to eq true
      end
    end
  end
end
