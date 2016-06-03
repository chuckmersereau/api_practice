require 'spec_helper'

describe DataServer::AccountAddressUpdatesPreparer, '#perform' do
  it 'preps contacts with DataServer donors for address updates' do
    account_list = create(:account_list)
    contact = create(:contact, account_list: account_list)
    org = create(:organization, api_class: 'DataServerPtc')
    donor_account = create(:donor_account, organization: org)
    contact.donor_accounts << donor_account
    updates_prep = instance_double(DataServer::ContactAddressUpdatesPrep,
                                   prep_for_address_auto_updates: nil)
    allow(DataServer::ContactAddressUpdatesPrep).to receive(:new) do |prep_contact|
      expect(prep_contact).to eq(contact)
      updates_prep
    end
    # make sure it exludes a contact not associated with a donor account
    create(:contact, account_list: account_list)

    DataServer::AccountAddressUpdatesPreparer.new.perform(account_list.id)

    expect(updates_prep).to have_received(:prep_for_address_auto_updates)
  end
end
