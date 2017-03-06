require 'rails_helper'

describe AccountListUser do
  context '#after_destroy' do
    context '#change_user_default_account_list' do
      let(:first_account_list) { create(:account_list) }
      let(:second_account_list) { create(:account_list) }
      let(:user) { create(:user, account_lists: [first_account_list, second_account_list], default_account_list: first_account_list.id) }

      it 'sets a new default_account_list when previous default account list is no longer available to the user' do
        expect(user.default_account_list).to eq(first_account_list.id)
        first_account_list.account_list_users.first.destroy
        expect(user.reload.default_account_list).to eq(second_account_list.id)
      end
    end
  end
end
