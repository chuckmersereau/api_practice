require 'spec_helper'

describe Admin::AccountPrimaryAddressesFix, '#fix!' do
  it 'fixes the primary addresses for each contact in the account list' do
    contact = create(:contact)
    contacts = double('contacts')
    allow(contacts).to receive(:find_each).and_yield(contact)
    account_list = double('account_list', contacts: contacts)
    fix = double('fix', fix: nil)
    allow(Admin::PrimaryAddressFix).to receive(:new).with(contact) { fix }

    Admin::AccountPrimaryAddressesFix.new(account_list).fix

    expect(fix).to have_received(:fix)
  end
end
