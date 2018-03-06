require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Monthly Losses Graphs Report' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:reports, :monthly_losses_graphs])

  let(:resource_type) { 'reports_monthly_losses_graphs' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:resource_attributes) do
    %w(
      created_at
      account_list
      losses
      month_names
      updated_at
      updated_in_db_at
    )
  end

  let(:id) { account_list_id }

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/monthly_losses_graphs/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
