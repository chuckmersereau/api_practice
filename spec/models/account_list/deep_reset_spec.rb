require 'spec_helper'

describe AccountList::DeepReset, '#reset' do
  it 'does nothing if called for a non-existing account list / user' do
    expect do
      AccountList::DeepReset.new(-1, -2).reset
    end.to_not raise_error
  end

  it 'destroys the account and queues a donor data import' do
    user = create(:user)
    org_account = instance_double(Person::OrganizationAccount, queue_import_data: nil)
    allow(User).to receive(:find_by).with(id: user.id) { user }
    allow(user).to receive(:organization_accounts) { [org_account] }
    account_list = create(:account_list)
    user.account_lists << account_list

    expect do
      AccountList::DeepReset.new(account_list.id, user.id).reset
    end.to change(AccountList, :count).by(-1)

    expect(org_account).to have_received(:queue_import_data)
  end
end
