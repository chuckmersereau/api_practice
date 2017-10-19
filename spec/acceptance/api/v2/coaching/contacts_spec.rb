require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Coaching Contacts' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: %i(coaching contacts))

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user) }
  let!(:coach)        { user.becomes(User::Coach) }

  let(:account_list) do
    create(:account_list).tap do |account_list|
      coach.coaching_account_lists << account_list
    end
  end

  let!(:contact) do
    create :contact, account_list_id: account_list.id, pledge_received: true
  end

  let!(:contact_outstanding) do
    create :contact, account_list_id: account_list.id, pledge_received: false,
                     pledge_start_date: 2.days.ago
  end

  let!(:contact_pending) do
    create :contact, account_list_id: account_list.id, pledge_received: false,
                     pledge_start_date: 2.days.from_now
  end

  let!(:contact_completed_start_past) do
    create :contact, account_list_id: account_list.id, pledge_received: true,
                     pledge_start_date: 2.days.ago
  end

  let!(:contact_completed_start_future) do
    create :contact, account_list_id: account_list.id, pledge_received: true,
                     pledge_start_date: 2.days.from_now
  end

  let(:id) { contact.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      late_at
      locale
      name
      pledge_amount
      pledge_currency
      pledge_currency_symbol
      pledge_frequency
      pledge_received
      pledge_start_date
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(coach) }

    get '/api/v2/coaching/contacts' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource 5
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/coaching/contacts/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource
        expect(resource_object['pledge_amount']).to eq contact.pledge_amount.to_s
        expect(response_status).to eq 200
      end
    end
  end
end
