require 'rails_helper'

describe RunOnce::AccountPasswordRemovalWorker do
  subject { described_class.new.perform }

  it 'removes some passwords' do
    account_with_token = create(:organization_account, token: 'asdf')
    account_without_token = create(:organization_account)

    subject

    expect(account_with_token.reload.password).to be nil
    expect(account_without_token.reload.password).to_not be nil
  end
end
