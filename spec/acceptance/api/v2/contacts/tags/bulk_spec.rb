require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Tags > Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :tags])

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:tag_one) { 'tag_one' }
  let(:tag_two) { 'tag_two' }

  let!(:contact_one)   { create(:contact, account_list: account_list, tag_list: [tag_one, tag_two]) }
  let!(:contact_two)   { create(:contact, account_list: account_list, tag_list: [tag_one]) }
  let!(:contact_three) { create(:contact, account_list: account_list, tag_list: [tag_one]) }

  let(:contact_ids) { [contact_one, contact_two].map(&:uuid).join(', ') }

  let(:form_data) do
    {
      data: {
        type: 'tag',
        attributes: {
          name: 'tag_one'
        }
      }
    }.merge(filter_params)
  end

  let(:filter_params) do
    {
      filter: {
        contact_ids: contact_ids
      }
    }
  end

  context 'authorized user' do
    before { api_login(user) }

    before do
      expect(contact_one.tag_list.count).to   eq 2
      expect(contact_two.tag_list.count).to   eq 1
      expect(contact_three.tag_list.count).to eq 1
    end

    # destroy
    delete '/api/v2/contacts/tags/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_delete, context: self)

      example doc_helper.title_for(:bulk_delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_delete)
        do_request form_data

        expect(response_status).to eq(204), invalid_status_detail

        expect(contact_one.reload.tag_list.count).to   eq 1
        expect(contact_two.reload.tag_list.count).to   eq 0
        expect(contact_three.reload.tag_list.count).to eq 1
      end
    end
  end
end
