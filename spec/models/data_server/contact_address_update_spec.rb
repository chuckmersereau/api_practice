require 'spec_helper'

describe DataServer::ContactAddressUpdate, '#update_from_donor_accont' do
  let(:contact) { create(:contact) }
  let(:donor_account) { create(:donor_account) }
  before do
    contact.donor_accounts << donor_account
  end

  it 'does not add the most recent address if it already exists on contact' do
    address1 = create(:address, street: '1 Rd')
    address2 = create(:address, street: '2 Rd', created_at: 2.days.ago)
    donor_account.addresses << [address1, address2]
    contact.addresses << create(:address, street: '1 Rd')

    DataServer::ContactAddressUpdate.new(contact, donor_account).update_from_donor_account

    expect(contact.addresses.count).to eq 1
    expect(contact.addresses.first.street).to eq '1 Rd'
  end

  it 'adds address as non-primary if contact primary address not from DataServer' do
    address1 = create(:address, street: '1 DataServer Rd', primary_mailing_address: true)
    address2 = create(:address, street: '2 DataServer Rd', created_at: 2.days.ago)
    donor_account.addresses << [address1, address2]
    contact.addresses << create(:address, street: 'Tnt Rd', source: 'TntImport',
                                          primary_mailing_address: true)

    DataServer::ContactAddressUpdate.new(contact, donor_account).update_from_donor_account

    expect(contact.addresses.count).to eq 2
    expect(contact.reload.primary_address.street).to eq 'Tnt Rd'
    expect(contact.addresses.map(&:street)).to include '1 DataServer Rd'
  end

  it 'adds address as primary if contact primary address is from DataServer' do
    donor_account.addresses << create(:address, street: 'New DataServer',
                                                primary_mailing_address: true)
    contact.addresses << create(:address, street: 'Old DataServer', source: 'DataServer',
                                          primary_mailing_address: true)

    DataServer::ContactAddressUpdate.new(contact, donor_account).update_from_donor_account

    expect(contact.addresses.count).to eq 2
    expect(contact.addresses.where(primary_mailing_address: true).count).to eq 1
    expect(contact.reload.primary_address.street).to eq 'New DataServer'
    expect(contact.addresses.map(&:street)).to include 'Old DataServer'
  end

  it 'adds address as primary if contact has no non-historic addresses' do
    donor_account.addresses << create(:address, street: '1 DataServer')
    contact.addresses << create(:address, street: 'Historic Way', source: 'DataServer',
                                          historic: true)

    DataServer::ContactAddressUpdate.new(contact, donor_account).update_from_donor_account

    expect(contact.addresses.count).to eq 2
    expect(contact.reload.primary_address.street).to eq '1 DataServer'
    expect(contact.addresses.map(&:street)).to include 'Historic Way'
  end
end
