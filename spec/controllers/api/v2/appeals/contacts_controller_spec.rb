require 'rails_helper'

describe Api::V2::Appeals::ContactsController, type: :controller do
  let(:factory_type) { :contact }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.uuid }
  let!(:contact) { create(:contact, account_list: account_list, appeals: [appeal]) }
  let!(:second_contact) { create(:contact, account_list: account_list, appeals: [appeal]) }
  let(:unassociated_contact) { create(:contact, account_list: account_list) }
  let(:id) { contact.uuid }

  let(:resource) { contact }
  let(:parent_param) { { appeal_id: appeal_id, filters: { account_list_id: account_list_id, excluded: 0 } } }
  let(:correct_attributes) { {} }

  before do
    resource.addresses << create(:address) # Test inclusion of related resources.
  end

  include_examples 'index_examples'

  describe '#create' do
    let!(:contact) { create(:contact, account_list: account_list) }
    include_context 'common_variables'
    include_examples 'including related resources examples', action: :create, expected_response_code: 200
    include_examples 'sparse fieldsets examples', action: :create, expected_response_code: 200

    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
        appeal.contacts.reload
      end.to change { appeal.contacts.count }.by(1)
      expect(response.status).to eq(200)
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
        appeal.contacts.reload
      end.not_to change { appeal.contacts.count }
      expect(response.status).to eq(401)
    end
  end

  include_examples 'show_examples'

  describe '#destroy' do
    include_context 'common_variables'

    it 'destroys resource object to users that are signed in' do
      api_login(user)
      expect do
        delete :destroy, full_params
        appeal.contacts.reload
      end.to change { appeal.contacts.count }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
          appeal.contacts.reload
        end.not_to change { appeal.contacts.count }
        expect(response.status).to eq(403)
      end
    end

    it 'does not destroy resource object to users that are signed in' do
      expect do
        delete :destroy, full_params
        appeal.contacts.reload
      end.not_to change { appeal.contacts.count }
      expect(response.status).to eq(401)
    end
  end
end
