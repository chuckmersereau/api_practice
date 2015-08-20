require 'spec_helper'

describe LowerRetryWorker do
  it 'calls the specified method on the given class' do
    account = build_stubbed(:account_list)
    expect(AccountList).to receive(:find).with(account.id) { account }
    expect(account).to receive(:import_data)
    LowerRetryWorker.new.perform('AccountList', account.id, 'import_data')
  end

  it 'does nothing if the record is not found' do
    expect do
      LowerRetryWorker.new.perform('AccountList', -1, 'import_data')
    end.to_not raise_error
  end
end
