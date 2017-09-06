require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :account_lists)

  let(:resource_type) { 'account_lists' }
  let!(:user)         { create(:user) }

  let(:account_list) do
    create(:account_list).tap do |account_list|
      user.account_lists << account_list
    end
  end

  let(:id) { account_list.uuid }

  let(:new_account_list) do
    attributes_for(:account_list)
      .except(:creator_id)
      .merge(updated_in_db_at: account_list.updated_at)
  end

  let(:form_data) { build_data(new_account_list) }

  let(:resource_attributes) do
    %w(
      created_at
      currency
      default_currency
      home_country
      monthly_goal
      name
      salary_organization
      tester
      total_pledges
      active_mpd_start_at
      active_mpd_finish_at
      active_mpd_monthly_goal
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      notification_preferences
      organization_accounts
      primary_appeal
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      before { account_list }

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(['relationships'])
        expect(resource_object['name']).to eq account_list.name
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/account_lists/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        expect(resource_object['name']).to eq new_account_list[:name]
        expect(response_status).to eq 200
      end
    end
  end
end
