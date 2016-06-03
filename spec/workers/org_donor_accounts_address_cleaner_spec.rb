require 'spec_helper'

describe OrgDonorAccountsAddressCleaner, '#perform' do
  it 'merges donor account addresses and sets source to DataServer' do
    org = create(:organization, api_class: 'DataServer')
    donor_account = create(:donor_account, organization: org)
    address1 = create(:address, street: '1 Way', source: nil)
    address2 = create(:address, street: '1 way', source: nil)
    address3 = create(:address, street: '2 Way', source: nil)
    donor_account.addresses << [address1, address2, address3]

    OrgDonorAccountsAddressCleaner.new.perform(org.id)

    expect(donor_account.reload.addresses.count).to eq 2
    expect(donor_account.addresses.map(&:source).uniq).to eq ['DataServer']
  end
end
