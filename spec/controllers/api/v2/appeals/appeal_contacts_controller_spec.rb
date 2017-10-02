require 'rails_helper'

describe Api::V2::Appeals::AppealContactsController, type: :controller do
  let(:factory_type) { :appeal_contact }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:appeal_contact) { create(:appeal_contact, appeal: appeal, contact: contact) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let!(:second_appeal_contact) { create(:appeal_contact, appeal: appeal, contact: second_contact) }
  let(:unassociated_contact) { create(:contact, account_list: account_list) }
  let(:id) { appeal_contact.uuid }

  let(:resource) { appeal_contact }
  let(:parent_param) { { appeal_id: appeal_id } }
  let(:correct_attributes) { {} }
  let(:correct_relationships) do
    {
      contact: {
        data: {
          type: 'contacts',
          id: unassociated_contact.uuid
        }
      }
    }
  end

  include_examples 'index_examples'

  describe 'filtering' do
    before { api_login(user) }

    context 'pledged_to_appeal filter' do
      let!(:user) { create(:user_with_account) }

      before { create(:pledge, contact: contact, appeal: appeal, account_list: account_list) }

      it 'filters results' do
        get :index, appeal_id: appeal_id, filter: { pledged_to_appeal: 'true' }

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
      end
    end
  end

  describe '#create' do
    let!(:contact) { create(:contact, account_list: account_list) }
    include_context 'common_variables'
    include_examples 'including related resources examples', action: :create, expected_response_code: 200
    include_examples 'sparse fieldsets examples', action: :create, expected_response_code: 200

    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
        appeal.appeal_contacts.reload
      end.to change { appeal.appeal_contacts.count }.by(1)
      expect(response.status).to eq(200)
    end

    context 'excluded_appeal_contact exists' do
      let!(:appeal_excluded_appeal_contact) do
        create(:appeal_excluded_appeal_contact,
               contact: unassociated_contact,
               appeal: appeal)
      end

      it 'destroys appeal_excluded_appeal_contact' do
        api_login(user)
        expect do
          post :create, full_correct_attributes
          appeal.appeal_contacts.reload
        end.to change { appeal.excluded_appeal_contacts.count }.by(-1)
        expect(response.status).to eq(200)
      end
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
        appeal.appeal_contacts.reload
      end.not_to change { appeal.appeal_contacts.count }
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
        appeal.appeal_contacts.reload
      end.to change { appeal.appeal_contacts.count }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
          appeal.appeal_contacts.reload
        end.not_to change { appeal.appeal_contacts.count }
        expect(response.status).to eq(403)
      end
    end

    it 'does not destroy resource object to users that are signed in' do
      expect do
        delete :destroy, full_params
        appeal.appeal_contacts.reload
      end.not_to change { appeal.appeal_contacts.count }
      expect(response.status).to eq(401)
    end
  end
end
