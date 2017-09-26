require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Background Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :background_batches)

  before do
    stub_request(:get, 'https://api.mpdx.org/api/v2/user')
      .to_return(status: 200,
                 body: '{"id": 1234}',
                 headers: { accept: 'application/json' })
  end

  let!(:user)             { create(:user_with_full_account) }
  let!(:background_batch) { create(:background_batch, user: user) }
  let(:resource_type)     { 'background_batches' }
  let(:excluded)          { 0 }
  let(:id)                { background_batch.uuid }

  let(:form_data) do
    attributes = attributes_for(:background_batch).except(:user_id)
    build_data(attributes, relationships: relationships)
  end

  let(:relationships) do
    {
      requests: {
        data: [
          {
            type: 'background_batch_requests',
            id: SecureRandom.uuid,
            attributes: {
              path: 'api/v2/user'
            }
          }
        ]
      }
    }
  end

  let(:resource_attributes) do
    %w(
      created_at
      pending
      total
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_asociations) do
    %w(
      requests
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/background_batches' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    get '/api/v2/background_batches/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(%w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    post '/api/v2/background_batches' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail

        background_batch = BackgroundBatch.find_by(uuid: json_response['data']['id'])
        expect(background_batch.requests.length).to eq(1)
      end
    end

    delete '/api/v2/background_batches/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request

        expect(response_status).to eq(204), invalid_status_detail
      end
    end
  end
end
