require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'ChurchNames' do
  include_context :json_headers
  documentation_scope = :church_names_api

  let(:factory_type) { :church_names }
  # first user
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:church_name) { 'Beautiful Saviour' }
  let(:second_church_name) { 'Cross of Christ' }
  let(:third_church_name) { 'Calvary Chapel' }

  let!(:contact) { create(:contact, account_list: account_list, church_name: church_name) }
  let!(:second_contact) { create(:contact, account_list: account_list, church_name: second_church_name) }
  let!(:third_contact) { create(:contact, account_list: account_list, church_name: third_church_name) }

  let(:resource_attributes) do
    %w(
      church_name
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/church_names' do
      parameter 'church_name_like', 'Church Name Search [OPTIONAL]', scope: :filter

      example 'Church Names [LIST]', document: documentation_scope do
        explanation 'List Church Names'
        do_request

        expect(response_status).to eq(200)
      end
    end
  end
end
