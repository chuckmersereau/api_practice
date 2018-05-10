require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Appointments Report' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:reports, :appointment_results])

  let(:resource_type) { 'reports_appointment_results_periods' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:resource_attributes) do
    %w(
      created_at
      start_date
      end_date
      individual_appointments
      group_appointments
      new_monthly_partners
      new_special_pledges
      monthly_increase
      pledge_increase
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/reports/appointment_results/' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request
        check_collection_resource(4)
        expect(response_status).to eq 200
      end
    end
  end
end
