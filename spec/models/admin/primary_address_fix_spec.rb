require 'spec_helper'

describe Admin::PrimaryAddressFix, '#fix' do
  let(:contact) { create(:contact) }

  it 'sets non-primary address to primary' do
    address1 = create(:address, primary_mailing_address: false)
    contact.addresses << address1

    Admin::PrimaryAddressFix.new(contact).fix

    expect(address1.reload).to be_primary_mailing_address
  end

  it 'does not create a new address if there are none' do
    Admin::PrimaryAddressFix.new(contact).fix

    expect(contact.addresses.count).to eq 0
  end

  it 'sets mailing address to primary in case with two non-primary addresses' do
    address1 = create(:address, primary_mailing_address: false)
    address2 = create(:address, primary_mailing_address: false)
    allow(contact).to receive(:addresses)
      .and_return(Address.where(id: [address1.id, address2.id]))
    allow(contact).to receive(:mailing_address) { address1 }

    Admin::PrimaryAddressFix.new(contact).fix

    expect(address1.reload).to be_primary_mailing_address
    expect(address2.reload).to_not be_primary_mailing_address
  end

  it 'does not set historic address to primary' do
    address = create(:address, primary_mailing_address: false, historic: true)
    contact.addresses << address

    Admin::PrimaryAddressFix.new(contact).fix

    expect(address.reload).to_not be_primary_mailing_address
  end

  it 'sets mailing address as the only primary if had two primary addresses' do
    address1 = create(:address, primary_mailing_address: true)
    address2 = create(:address, primary_mailing_address: true)
    allow(contact).to receive(:addresses)
      .and_return(Address.where(id: [address1.id, address2.id]))
    allow(contact).to receive(:mailing_address) { address1 }

    Admin::PrimaryAddressFix.new(contact).fix

    expect(address1.reload).to be_primary_mailing_address
  end

  it 'set historic addresses to non-primary' do
    address = create(:address, primary_mailing_address: true, historic: true)
    contact.addresses << address

    Admin::PrimaryAddressFix.new(contact).fix

    expect(address.reload).to_not be_primary_mailing_address
  end
end
