require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Designation Accounts' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: %i(account_lists designation_accounts))

  let(:resource_type) { 'designation_accounts' }
  let(:user)          { create(:user_with_account) }

  let(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:designation_account) { create(:designation_account) }
  let(:id)                  { designation_account.id }

  let(:new_designation_account) { { active: true, overwrite: true } }

  let(:expected_attribute_keys) do
    %w(
      active
      display_name
      balance
      balance_updated_at
      converted_balance
      created_at
      currency
      currency_symbol
      designation_number
      exchange_rate
      name
      organization_name
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      balances
      organization
    )
  end

  context 'authorized user' do
    before do
      account_list.designation_accounts << designation_account
      api_login(user)
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request
        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts/:id' do
      doc_helper.insert_documentation_for(action: :get, context: self)

      example doc_helper.title_for(:get), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:get)
        explanation 'The Designation Account with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['designation_number']).to eq designation_account.designation_number
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/account_lists/:account_list_id/designation_accounts/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: build_data(new_designation_account)
        expect(response_status).to eq(200), invalid_status_detail
        expect(resource_object['active']).to eq new_designation_account[:active]
      end
    end
  end
end
