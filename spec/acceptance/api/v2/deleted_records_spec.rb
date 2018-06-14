require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'DeletedRecords' do
  include_context :json_headers
  documentation_scope = :deleted_records_api

  let(:factory_type) { :deleted_record }
  # first user
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.current - 1.day) }
  let!(:second_resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.current - 1.day) }
  let!(:third_resource) { create(:deleted_record, account_list: account_list, deleted_by: user, deleted_at: Date.current - 2.years) }
  let!(:second_deleted_task_record) do
    create(:deleted_task_record, account_list: account_list, deleted_by: user, deleted_at: Date.current - 2.years)
  end

  let(:resource_attributes) do
    %w(
      deletable_id
      deletable_type
      deleted_at
      deleted_by_id
      created_at
      updated_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/deleted_records' do
      parameter 'since_date', 'A Date Object/String', scope: :filter
      parameter 'types', 'Contact, Activity', scope: :filter

      example 'Deleted Records [LIST]', document: documentation_scope do
        explanation 'List Deleted Records'
        do_request filter: { since_date: (Date.today - 1.year), types: 'Contact' }

        expect(response_status).to eq(200)
      end
    end
  end
end
