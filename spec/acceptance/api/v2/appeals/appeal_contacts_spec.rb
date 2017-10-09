require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals > AppealContacts' do
  include_context :json_headers
  documentation_scope = :appeals_api_appeal_contacts

  let(:resource_type)  { 'appeal_contacts' }
  let!(:user)          { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:appeal)         { create(:appeal, account_list: account_list) }
  let(:appeal_id)       { appeal.uuid }
  let!(:contact)        { create(:contact, account_list: account_list) }
  let!(:new_contact)    { create(:contact, account_list: account_list) }
  let!(:appeal_contact) { create(:appeal_contact, appeal: appeal, contact: contact) }
  let(:id)              { appeal_contact.uuid }

  let(:resource_attributes) do
    %w(
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

    get '/api/v2/appeals/:appeal_id/appeal_contacts' do
      with_options scope: :filter do
        parameter 'account_list_id', 'Account List ID', type: 'String'
        parameter 'pledged_to_appeal',
                  'has contact has pledged to appeal? Accepts value "true" or "false"',
                  required: false,
                  type: 'String'
      end
      with_options scope: :sort do
        parameter 'contact.name', 'Sort by Contact Name', type: 'String'
      end

      response_field 'data',       'Data', type: 'Array[Object]'

      example 'AppealContact [LIST]', document: documentation_scope do
        explanation 'List of Contacts associated to the Appeal'
        do_request
        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq 200
      end
    end

    post 'api/v2/appeals/:appeal_id/appeal_contacts' do
      let(:relationships) do
        {
          contact: {
            data: {
              type: 'contacts',
              id: new_contact.uuid
            }
          }
        }
      end
      let!(:form_data) { build_data(attributes_for(:appeal_contact, appeal: appeal), relationships: relationships) }

      example 'AppealContact [POST]', document: documentation_scope do
        explanation 'Add a contact to an Appeal'
        do_request data: form_data
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/appeals/:appeal_id/appeal_contacts/:id' do
      with_options scope: [:data, :attributes] do
      end

      example 'AppealContact [GET]', document: documentation_scope do
        explanation 'The Appeal Contact with the given ID'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/appeals/:appeal_id/appeal_contacts/:id' do
      parameter 'id', 'ID', required: true

      example 'AppealContact [DELETE]', document: documentation_scope do
        explanation 'Remove the Contact with the given ID from the Appeal'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
