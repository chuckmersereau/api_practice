require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Exports' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :exports])

  let!(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact_with_person, account_list: user.account_lists.order(:created_at).first) }
  let(:resource) { create(:export_log, user: user, params: { filter: { status: 'active' } }.to_json) }
  let(:resource_type) { 'export_logs' }
  let(:id) { resource.id }
  let(:new_resource) do
    {
      params: {
        filter: {
          status: 'active'
        }
      }
    }
  end
  let(:form_data) do
    build_data(new_resource)
  end
  let(:additional_keys) { ['relationships'] }
  let(:additional_attributes) { %w(params) }

  context 'authorized user' do
    before { api_login(user) }

    # the INDEX action has been deprecated in favor of using the CREATE and SHOW method
    # as this better supports a wider range of browsers as the API now generates
    # the file for the user to download.

    # The following two tests remain to ensure backwards compatibility.

    get '/api/v2/contacts/exports.csv' do
      example doc_helper.title_for(:index_csv), document: false do
        do_request
        expect(response_status).to eq 200
        expect(response_body).to include(contact.name)
        expect(response_headers['Content-Type']).to eq('text/csv')
      end
    end

    get '/api/v2/contacts/exports.xlsx' do
      example doc_helper.title_for(:index_xlsx), document: false do
        do_request
        expect(response_status).to eq 200
        expect(response_headers['Content-Type']).to eq(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
      end
    end

    get '/api/v2/contacts/exports/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)
      with_options scope: :relationships do
        response_field :user, 'User Object', 'Type' => 'Object'
      end

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(additional_keys, additional_attributes)
        expect(resource_object['params']).to eq JSON.parse(new_resource[:params].to_json)
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/exports' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail
        expect(resource_object['params']).to eq JSON.parse(new_resource[:params].to_json)
      end
    end
  end
end
