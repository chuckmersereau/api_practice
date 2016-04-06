require 'spec_helper'

describe AccountList::Reset, '#reset_shallow_and_queue_deep' do
  it 'destroys the users links and queues the deep reset worker' do
    user = create(:user)
    account_list = create(:account_list)
    user.account_lists << account_list
    allow(AccountList::DeepResetWorker).to receive(:perform_async)

    expect do
      AccountList::Reset.new(account_list, user).reset_shallow_and_queue_deep
    end.to change(AccountListUser, :count).by(-1)

    expect(user.account_lists.reload).to be_empty
    expect(AccountList::DeepResetWorker).to have_received(:perform_async)
      .with(account_list.id, user.id)
  end
end
