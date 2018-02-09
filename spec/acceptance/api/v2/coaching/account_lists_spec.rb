require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Coaching Account Lists' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: %i(coaching account_lists))

  let(:resource_type) { 'account_lists' }
  let!(:user)         { create(:user) }
  let!(:coach)        { user.becomes(User::Coach) }

  let(:account_list) do
    create(:account_list).tap do |account_list|
      coach.coaching_account_lists << account_list
    end
  end

  let(:id) { account_list.id }

  let(:new_account_list) do
    attributes_for(:account_list)
      .except(:creator_id)
      .merge(updated_in_db_at: account_list.updated_at)
  end

  let(:form_data) { build_data(new_account_list) }

  let(:resource_attributes) do
    %w(
      active_mpd_finish_at
      active_mpd_monthly_goal
      active_mpd_start_at
      balance
      committed
      created_at
      currency
      default_currency
      home_country
      last_prayer_letter_at
      monthly_goal
      name
      progress
      received
      salary_organization
      staff_account_ids
      tester
      total_pledges
      updated_at
      updated_in_db_at
      weeks_on_mpd
    )
  end

  let(:resource_associations) do
    %w(
      notification_preferences
      organization_accounts
      primary_appeal
      users
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/coaching/account_lists' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      before { account_list }

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/coaching/account_lists/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(['relationships'])
        expect(resource_object['name']).to eq account_list.name
        expect(response_status).to eq 200
      end
    end
  end
end
