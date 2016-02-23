require 'spec_helper'

describe Admin::PrimaryAddressFixWorker, '#perform' do
  it 'finds account list and runs primary address fix for each contact in it' do
    contact = double('contact')
    contacts = double('contacts')
    allow(contacts).to receive(:find_each).and_yield(contact)
    account_list = double('account_list', contacts: contacts)
    allow(AccountList).to receive(:find).with(1) { account_list }
    worker = Admin::PrimaryAddressFixWorker.new
    primary_address_fix = double('primary_address_fix', fix!: nil)
    allow(Admin::PrimaryAddressFix).to receive(:new)
      .with(contact) { primary_address_fix }

    worker.perform(1)

    expect(primary_address_fix).to have_received(:fix!)
  end
end
