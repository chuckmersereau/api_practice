require 'spec_helper'

describe AccountList::DeepResetWorker, '#perform' do
  it 'runs a deep reset for the given account list id and user id' do
    account_list_id = 1
    user_id = 2
    reset = double(reset: nil)
    allow(AccountList::DeepReset).to receive(:new) { reset }

    Sidekiq::Testing.inline! do
      AccountList::DeepResetWorker.perform_async(account_list_id, user_id)
    end

    expect(AccountList::DeepReset).to have_received(:new).with(account_list_id, user_id)
    expect(reset).to have_received(:reset)
  end
end
