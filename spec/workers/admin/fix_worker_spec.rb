require 'rails_helper'

describe Admin::FixWorker, '#perform' do
  let(:id) { SecureRandom.uuid }
  it 'finds account list and runs the specified fix for it' do
    account_list = double('account_list')
    allow(AccountList).to receive(:find).with(id) { account_list }
    fix = double('fix', fix: nil)
    allow(Admin::AccountPrimaryAddressesFix).to receive(:new)
      .with(account_list) { fix }

    Admin::FixWorker.new.perform('account_primary_addresses', 'AccountList', id)

    expect(fix).to have_received(:fix)
  end
end
