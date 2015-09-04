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

  context '#merge' do
    let(:winner) { create(:donor_account) }
    let(:loser) { create(:donor_account) }
    let(:donation1) { create(:donation, donation_date: Date.today) }
    let(:donation2) { create(:donation, donation_date: Date.yesterday) }
    let(:donor_account) { create(:donor_account) }
    let(:mpda) do
      create(:master_person_donor_account, donor_account: donor_account)
    end
    let(:contact_donor_account) do
      create(:contact_donor_account, contact: create(:contact),
                                     donor_account: donor_account)
    end

    before do
      winner.donations << donation1
      winner.update_donation_totals(donation1)
      loser.donations << donation2
      loser.update_donation_totals(donation2)
      loser.master_person_donor_accounts << mpda
      loser.contact_donor_accounts << contact_donor_account
    end

    it 'returns false and does nothing if account numbers differ' do
      loser.update(account_number: 'different number')
      expect do
        expect(winner.merge(loser)).to be false
      end.to_not change(DonorAccount, :count)
    end

    it 'combines donor account data' do
      expect do
        winner.merge(loser)
      end.to change(DonorAccount, :count).by(-1)
      winner.reload
      expect(winner.total_donations).to eq(9.99 * 2)
      expect(winner.last_donation_date).to eq Date.today
      expect(winner.first_donation_date).to eq Date.yesterday
      expect(winner.donations.to_set).to eq([donation1, donation2].to_set)
      expect(winner.master_person_donor_accounts.to_a).to eq [mpda]
      expect(winner.contact_donor_accounts.to_a).to eq [contact_donor_account]
    end
  end
end
