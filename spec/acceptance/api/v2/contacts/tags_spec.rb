require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Tags' do
  let(:resource_type) { 'contacts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.id }
  let(:tag_name) { 'new_tag' }
  let(:new_tag_params) { { name: tag_name } }
  let(:form_data) { build_data(new_tag_params) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    post '/api/v2/contacts/:contact_id/tags' do
      with_options scope: [:data, :attributes] do
        parameter :name, 'name of Tag'
      end

      example 'create tag' do
        do_request data: form_data
        expect(resource_object['tag-list'].first).to eq new_tag_params[:name]
        expect(status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/tags/:tag_name' do
      parameter :contact_id, 'the Contact id of the Tag'
      parameter :tag_name, 'the Id of the Tag'

      example_request 'delete tag' do
        expect(status).to eq 200
      end
    end
  end
end