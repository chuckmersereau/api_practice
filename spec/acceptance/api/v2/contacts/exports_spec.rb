require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Exports' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :exports])

  let!(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists.first) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/exports.csv' do
      doc_helper.insert_documentation_for(action: :index_csv, context: self)

      example doc_helper.title_for(:index_csv), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index_csv)
        do_request
        expect(response_status).to eq 200
        expect(response_body).to include(contact.name)
        expect(response_headers['Content-Type']).to eq('text/csv')
      end
    end

    # This has been removed because the response is logged in the documentation.
    # Unfortunately - since that response is .xlsx data, it won't correctly convert
    # from the documentation markdown to html.
    #
    # An alternative solution will have to be found in order to document this endpoint -
    # perhaps it can be manually done in the docs project.
    #
    # get '/api/v2/contacts/exports.xlsx' do
    #   doc_helper.insert_documentation_for(action: :index_xlsx, context: self)

    #   example doc_helper.title_for(:index_xlsx), document: doc_helper.document_scope do
    #     explanation doc_helper.description_for(:index_xlsx)
    #     do_request

    #     expect(response_status).to eq 200
    #     expect(response_headers['Content-Type']).to eq('application/xlsx')
    #   end
    # end
  end
end
