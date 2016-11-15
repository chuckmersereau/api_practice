require 'spec_helper'

describe Api::V2::AccountLists::InvitesController, type: :controller do
  let(:resource_type) { :account_list_invite }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:invite) { create(:account_list_invite, account_list: account_list) }
  let(:id) { invite.id }

  let(:resource) { invite }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { recipient_email: 'test@example.com' } }
  let(:incorrect_attributes) { { recipient_email: nil } }
  let(:unpermitted_attributes) { nil }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  describe '#destroy' do
    before do
      api_login(user)
    end
    it 'deletes a prayer letters account' do
      delete :destroy, account_list_id: account_list_id, id: id
      expect(response.status).to eq 200
    end
  end
end
