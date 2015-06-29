require 'spec_helper'

describe DonorAccount do
  before(:each) do
    @donor_account = create(:donor_account)
  end
  it 'should have one primary_master_person' do
    @mp1 = create(:master_person)
    @donor_account.master_people << @mp1
    expect(@donor_account.primary_master_person).to eq(@mp1)

    expect do
      @donor_account.master_people << create(:master_person)
      expect(@donor_account.primary_master_person).to eq(@mp1)
    end.to_not change(MasterPersonDonorAccount.primary, :count)
  end

  describe 'link_to_contact_for' do
    before do
      @account_list = create(:account_list)
    end
    it 'should return an alreay linked contact' do
      contact = create(:contact, account_list: @account_list)
      contact.donor_accounts << @donor_account
      expect(@donor_account.link_to_contact_for(@account_list)).to eq(contact)
    end

    it 'should link a contact based on a matching name' do
      contact = create(:contact, account_list: @account_list, name: @donor_account.name)
      new_contact = @donor_account.link_to_contact_for(@account_list)
      expect(new_contact).to eq(contact)
      expect(new_contact.donor_account_ids).to include(@donor_account.id)
    end

    # This feature was removed
    # it 'should link a contact based on a matching address' do
    # contact = create(:contact, account_list: @account_list)
    # a1 = create(:address, addressable: @donor_account)
    # a2 = create(:address, addressable: contact)
    # new_contact = @donor_account.link_to_contact_for(@account_list)
    # expect(new_contact).to eq(contact)
    # expect(new_contact.donor_account_ids).to include(@donor_account.id)
    # end

    it 'should create a new contact if no match is found' do
      expect do
        @donor_account.link_to_contact_for(@account_list)
      end.to change(Contact, :count)
    end

    it 'should not match to a contact with no addresses' do
      create(:contact, account_list: @account_list)
      create(:address, addressable: @donor_account)
      expect do
        @donor_account.link_to_contact_for(@account_list)
      end.to change(Contact, :count)
    end
  end
end
