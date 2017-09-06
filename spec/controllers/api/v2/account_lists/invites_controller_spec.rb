require 'rails_helper'

describe Api::V2::AccountLists::InvitesController, type: :controller do
  let(:factory_type) { :account_list_invite }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:invite) do
    create(:account_list_invite,
           account_list: account_list,
           invited_by_user: user,
           accepted_by_user: nil,
           cancelled_by_user: nil)
  end
  let!(:second_invite) do
    create(:account_list_invite,
           account_list: account_list,
           invited_by_user: user,
           accepted_by_user: nil,
           cancelled_by_user: nil)
  end
  let(:id) { invite.uuid }

  let(:resource) { invite }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { recipient_email: 'test@example.com' } }
  let(:incorrect_attributes) { { recipient_email: nil } }
  let(:unpermitted_attributes) { nil }

  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list_id
        }
      }
    }
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  describe '#update / accept' do
    let(:correct_attributes) { { code: invite.code } }

    before do
      api_login(user)
    end

    it 'returns a 401 when a user is not logged in' do
      api_logout
      expect do
        put :update, full_correct_attributes
      end.to_not change { invite.reload.accepted_at }
      expect(response.status).to eq 401
    end

    it 'returns a 400 when a blank code is passed' do
      full_correct_attributes[:data][:attributes][:code] = ''
      expect do
        put :update, full_correct_attributes
      end.to_not change { invite.reload.accepted_at }
      expect(response.status).to eq 400
    end

    it 'returns a 400 when the code is wrong' do
      full_correct_attributes[:data][:attributes][:code] = 'wrong code'
      expect do
        put :update, full_correct_attributes
      end.to_not change { invite.reload.accepted_at }
      expect(response.status).to eq 400
    end

    it 'returns a 404 when the id is not related to the account_list specified' do
      full_correct_attributes[:id] = create(:account_list_invite).uuid

      expect do
        put :update, full_correct_attributes
      end.to_not change { invite.reload.accepted_at }
      expect(response.status).to eq 404
    end

    it 'returns a 410 when the invite was cancelled' do
      invite.update(cancelled_by_user: create(:user))
      expect do
        put :update, full_correct_attributes
      end.to_not change { invite.reload.accepted_at }
      expect(response.status).to eq 410
    end

    it 'returns a 200 when the invite can be accepted' do
      expect do
        put :update, full_correct_attributes
      end.to change { invite.reload.accepted_at }
      expect(response.status).to eq 200
    end
  end

  describe '#destroy' do
    it 'returns a 401 when a user is not logged in' do
      expect do
        delete :destroy, account_list_id: account_list_id, id: id
      end.to_not change { invite.reload.cancelled_by_user }
      expect(response.status).to eq 401
    end

    it 'returns a 204 and deletes the invite when a user has correct access' do
      api_login(user)
      expect do
        delete :destroy, account_list_id: account_list_id, id: id
      end.to change { invite.reload.cancelled_by_user }
      expect(response.status).to eq 204
    end
  end
end
