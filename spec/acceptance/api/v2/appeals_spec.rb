require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :appeals)

  let(:resource_type)   { 'appeals' }
  let!(:user)           { create(:user_with_full_account) }
  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let!(:contact1)       { create(:contact, account_list: account_list, status: 'Partner - Pray') }
  let!(:contact2)       { create(:contact, account_list: account_list, status: 'Partner - Financial') }

  let(:excluded) { 0 }

  let!(:appeal)  do
    create(:appeal, account_list: account_list).tap do |appeal|
      create(:donation, appeal: appeal)
    end
  end

  let(:id) { appeal.id }

  let(:form_data) do
    attributes = attributes_for(:appeal).except(:account_list_id)
                                        .merge(
                                          updated_in_db_at: appeal.updated_at,
                                          inclusion_filter: { status: 'Partner - Financial,Partner - Pray' },
                                          exclusion_filter: { status: 'Partner - Financial' }
                                        )

    build_data(attributes, relationships: relationships)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      amount
      created_at
      currencies
      description
      end_date
      name
      pledges_amount_not_received_not_processed
      pledges_amount_processed
      pledges_amount_received_not_processed
      pledges_amount_total
      total_currency
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      contacts
      donations
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/appeals' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    get '/api/v2/appeals/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(%w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    post '/api/v2/appeals' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail

        appeal = Appeal.find_by(id: json_response['data']['id'])
        expect(appeal.appeal_contacts.first.contact_id).to eq(contact1.id)
        expect(appeal.excluded_appeal_contacts.first.contact_id).to eq(contact2.id)
      end
    end

    put '/api/v2/appeals/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data.except(:relationships)

        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    delete '/api/v2/appeals/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request

        expect(response_status).to eq(204), invalid_status_detail
      end
    end
  end
end
