require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Coaching Pledges' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: %i(coaching pledges))

  let(:resource_type) { 'pledges' }
  let(:user)         { create(:user) }
  let(:coach)        { user.becomes(User::Coach) }

  let(:account_list) do
    create(:account_list).tap do |account_list|
      coach.coaching_account_lists << account_list
    end
  end

  let(:contact_1) { create :contact, account_list: account_list }
  let(:contact_2) { create :contact, account_list: account_list }

  let(:appeal) { create :appeal, account_list: account_list }

  let!(:pledge_1) { create :pledge, appeal: appeal, account_list: account_list }
  let!(:pledge_2) { create :pledge, appeal: appeal, account_list: account_list }
  let!(:pledge_3) { create :pledge, appeal: appeal, account_list: account_list }

  let(:id) { pledge_1.id }

  let(:resource_attributes) do
    %w(
      amount
      created_at
      expected_date
      status
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before do
      api_login(coach)
    end

    get '/api/v2/coaching/pledges' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource 3, %w(relationships)
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/coaching/pledges/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource %w(relationships)
        expect(resource_object['amount']).to eq pledge_1.amount.to_s
        expect(response_status).to eq 200
      end
    end
  end
end
