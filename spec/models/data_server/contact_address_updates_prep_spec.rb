require 'spec_helper'

describe DataServer::ContactAddressUpdatesPrep, '#prep_for_auto_address_updates' do
  let(:contact) { create(:contact) }
  let(:donor_account) { create(:donor_account) }
  before do
    contact.donor_accounts << donor_account
  end

  it 'fixes address encodings and merges duplicate addresses' do
    donor_account.addresses << create(:address, street: '1 Liberté')
    contact.addresses << create(:address, street: old_encoding('1 Liberté'))
    contact.addresses << create(:address, street: '1 way')
    contact.addresses << create(:address, street: '1 Way')

    DataServer::ContactAddressUpdatesPrep.new(contact).prep_for_address_auto_updates

    expect(contact.addresses.count).to eq 2
    expect(contact.addresses.reload.pluck(:street)).to include '1 Liberté'
    expect(contact.addresses.reload.pluck(:street)).to include '1 Way'
  end

  it 'sets primary address source to manual if it differs from latest donor address' do
    donor_account.addresses << create(:address, street: 'DataServer Rd',
                                                primary_mailing_address: true)
    contact.addresses << create(:address, street: 'Original Rd',
                                          primary_mailing_address: true)

    DataServer::ContactAddressUpdatesPrep.new(contact).prep_for_address_auto_updates

    expect(contact.reload.primary_address.street).to eq 'Original Rd'
    expect(contact.primary_address.source).to eq Address::MANUAL_SOURCE
  end

  it 'sets primary address source to DataServer if it matches latest donor address' do
    donor_account.addresses << create(:address, street: 'DataServer Rd',
                                                primary_mailing_address: true)
    contact.addresses << create(:address, street: 'DataServer Rd', source: nil,
                                          primary_mailing_address: true)

    DataServer::ContactAddressUpdatesPrep.new(contact).prep_for_address_auto_updates

    expect(contact.addresses.count).to eq 1
    expect(contact.reload.primary_address.source).to eq 'DataServer'
  end

  it "imports missing addresses from donor account't there yet" do
    donor_account.addresses << create(:address, street: '1 Way')
    contact.addresses << create(:address, street: '2 Way')

    DataServer::ContactAddressUpdatesPrep.new(contact).prep_for_address_auto_updates

    expect(contact.addresses.reload.pluck(:street)).to contain_exactly('1 Way', '2 Way')
  end

  def old_encoding(str)
    str.unpack('C*').pack('U*')
  end
end
