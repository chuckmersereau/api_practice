require 'spec_helper'

describe DonationSyncsController do
  context '#create' do
    it 'triggers a donor import for the current account list' do
      user = create(:user_with_account)
      login(user)
      clear_uniqueness_locks

      expect do
        post :create
      end.to change(AccountList.jobs, :size).by(1)
    end
  end
end
