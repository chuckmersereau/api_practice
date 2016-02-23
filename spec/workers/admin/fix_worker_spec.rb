require 'spec_helper'

describe Admin::FixWorker, '#perform' do
  it 'finds account list and runs the specified fix for it' do
    account_list = double('account_list', contacts: contacts)
    allow(AccountList).to receive(:find).with(1) { account_list }
    worker = Admin::PrimaryAddressFixWorker.new

    allow(Admin::PrimaryAddressFix).to receive(:new)
      .with(contact) { primary_address_fix }

    worker.perform(1)

    expect(primary_address_fix).to have_received(:fix!)
  end
end
