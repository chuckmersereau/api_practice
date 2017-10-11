require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals > ExcludedAppealContacts' do
  include_context :json_headers
  documentation_scope = :appeals_api_excluded_appeal_contacts

  let(:resource_type)  { 'excluded_appeal_contacts' }
  let!(:user)          { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:appeal)         { create(:appeal, account_list: account_list) }
  let(:appeal_id)       { appeal.uuid }
  let!(:contact)        { create(:contact, account_list: account_list) }
  let!(:new_contact)    { create(:contact, account_list: account_list) }

  let!(:excluded_appeal_contact) { create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact) }
  let(:id)                       { excluded_appeal_contact.uuid }

  let(:resource_attributes) do
    %w(
      reasons
      created_at
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      contact
      appeal
    )
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/appeals/:appeal_id/excluded_appeal_contacts' do
      with_options scope: :sort do
        parameter 'contact.name', 'Sort by Contact Name', type: 'String'
      end
      response_field 'data', 'Data', type: 'Array[Object]'

      example 'ExcludedAppealContact [LIST]', document: documentation_scope do
        explanation 'List of Excluded Contacts associated to the Appeal'
        do_request
        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/appeals/:appeal_id/excluded_appeal_contacts/:id' do
      with_options scope: [:data, :attributes] do
      end

      example 'ExcludedAppealContact [GET]', document: documentation_scope do
        explanation 'The Excluded Appeal Contact with the given ID'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end
  end
end
