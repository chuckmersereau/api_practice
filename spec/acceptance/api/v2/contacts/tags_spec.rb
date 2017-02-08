require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Tags' do
  include_context :json_headers

  let(:resource_type) { :tags }
  let!(:user)         { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let(:tag_name)   { 'new_tag' }

  let(:new_tag_params) { { name: tag_name } }
  let(:form_data)      { build_data(new_tag_params) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/tags' do
      let!(:account_list_two) { create(:account_list) }
      let!(:contact_one) { create(:contact, account_list: account_list, tag_list: [tag_name]) }
      let!(:contact_two) { create(:contact, account_list: account_list_two, tag_list: [tag_name]) }
      before { user.account_lists << account_list_two }
      example 'Tag [LIST]', document: :contacts do
        explanation 'List Contact Tags'
        do_request
        expect(resource_data.count).to eq 1
        expect(first_or_only_item['type']).to eq 'tags'
        expect(resource_object.keys).to match_array(%w(name))
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/tags' do
      with_options scope: [:data, :attributes] do
        parameter 'name', 'name of Tag'
      end

      example 'Tag [CREATE]', document: :contacts do
        explanation 'Create a Tag associated with the Contact'
        do_request data: form_data
        expect(resource_object['tag_list'].first).to eq new_tag_params[:name]
        expect(response_status).to eq 201
      end
    end

    delete '/api/v2/contacts/:contact_id/tags/:tag_name' do
      parameter 'contact_id', 'the Contact id of the Tag'
      parameter 'tag_name',   'the Id of the Tag'

      example 'Tag [DELETE]', document: :contacts do
        explanation 'Delete the Contact\'s Tag with the given name'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
