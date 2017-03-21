require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > People > Twitter Accounts' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:people, :twitter_accounts])

  let(:resource_type) { 'twitter_accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account)   { twitter_accounts.first }
  let(:id)                { twitter_account.uuid }

  let(:new_twitter_account) do
    attributes_for(:twitter_account)
      .reject { |key| key.to_s.end_with?('_id') || key.to_s.in?(%w(secret token)) }
      .merge(updated_in_db_at: twitter_account.updated_at)
  end

  let(:form_data) { build_data(new_twitter_account) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      primary
      remote_id
      screen_name
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        expect(resource_object.keys).to match_array expected_attribute_keys
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request

        expect(response_status).to eq 204
      end
    end
  end
end
