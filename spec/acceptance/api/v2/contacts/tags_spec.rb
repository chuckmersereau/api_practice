require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tags' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:contact)   { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.id }

  let(:tag_name)   { 'new_tag' }

  let(:new_tag_params) { { name: tag_name } }
  let(:form_data)      { build_data(new_tag_params) }

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/contacts/:contact_id/tags' do
      with_options scope: [:data, :attributes] do
        parameter 'name', 'name of Tag'
      end

      example 'Tag [CREATE]', document: :contacts do
        do_request data: form_data
        expect(resource_object['tag_list'].first).to eq new_tag_params[:name]
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/tags/:tag_name' do
      parameter 'contact_id', 'the Contact id of the Tag'
      parameter 'tag_name',   'the Id of the Tag'

      example 'Tag [DELETE]', document: :contacts do
        do_request
        expect(response_status).to eq 200
      end
    end
  end
end
