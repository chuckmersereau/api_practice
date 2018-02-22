require 'rails_helper'

describe Api::V2::AccountLists::CoachesController, type: :controller do
  let(:resource_type) { 'users' }
  let(:factory_type) { :user }
  let!(:user) { create(:user_with_account) }
  let!(:coaches) { create_list(:user_coach, 2) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }
  let(:coach2) { coaches.last }
  let(:id) { coach2.id }
  let(:original_user_id) { user.id }

  before do
    account_list.coaches += coaches
    account_list.coaches << user.becomes(User::Coach)
  end

  let(:resource) { coach2 }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:user) }

  include_examples 'index_examples', except: [:includes, :sparse_fieldsets]

  include_examples 'show_examples', except: [:includes, :sparse_fieldsets]

  context 'authorized user' do
    before do
      api_login(user)
    end

    describe '#destroy' do
      it 'deletes an user' do
        delete :destroy, account_list_id: account_list_id, id: id
        expect(response.status).to eq 204
      end

      it 'does delete self' do
        delete :destroy, account_list_id: account_list_id, id: original_user_id
        expect(response.status).to eq 204
      end
    end
  end
end
