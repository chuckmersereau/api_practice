require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contact > DonationAmountRecommendations' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :donation_amount_recommendations])

  let(:resource_type)  { 'donation_amount_recommendations' }
  let!(:user)          { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact)        { create(:contact, account_list: account_list) }
  let(:contact_id)      { contact.uuid }

  let!(:organization) { create :organization }
  let!(:designation_account) { create :designation_account, organization: organization }
  let!(:donor_account) { create :donor_account, organization: organization }
  let!(:donation_amount_recommendation) do
    create(
      :donation_amount_recommendation,
      designation_account: designation_account,
      donor_account: donor_account
    )
  end
  let(:id) { donation_amount_recommendation.uuid }

  before do
    contact.donor_accounts << donor_account
  end

  let(:additional_attributes) do
    %w(
      created_at
      updated_at
      updated_in_db_at
    )
  end

  let(:additional_keys) do
    %w(
      relationships
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/donation_amount_recommendations' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_collection_resource(1, additional_keys)
      end
    end

    get '/api/v2/contacts/:contact_id/donation_amount_recommendations/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(additional_keys, additional_attributes)
        expect(resource_object['started_at']).to eq donation_amount_recommendation.started_at
        expect(response_status).to eq 200
      end
    end
  end
end
