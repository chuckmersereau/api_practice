require 'rails_helper'

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

  describe '#link_to_contact_for' do
    before do
      @account_list = create(:account_list)
    end

    it 'returns an already linked contact' do
      contact = create(:contact, account_list: @account_list)
      contact.donor_accounts << @donor_account
      expect(@donor_account.link_to_contact_for(@account_list)).to eq(contact)
    end

    it 'links a contact based on a matching name' do
      contact = create(:contact, account_list: @account_list, name: @donor_account.name)
      new_contact = @donor_account.link_to_contact_for(@account_list)
      expect(new_contact).to eq(contact)
      expect(new_contact.donor_account_ids).to include(@donor_account.id)
    end

    it 'creates a new contact if no match is found' do
      expect do
        @donor_account.link_to_contact_for(@account_list)
      end.to change(Contact, :count)
    end

    it 'does not match to a contact with no addresses' do
      create(:contact, account_list: @account_list)
      create(:address, addressable: @donor_account)
      expect do
        @donor_account.link_to_contact_for(@account_list)
      end.to change(Contact, :count)
    end

    context 'with a blank name' do
      before { @donor_account.update!(name: '') }

      it 'does not raise an ActiveRecord::RecordInvalid error' do
        expect do
          @donor_account.link_to_contact_for(@account_list)
        end.not_to raise_error
      end

      it 'creates a contact with a fallback name' do
        contact = @donor_account.link_to_contact_for(@account_list)
        expect(contact.name).to eq 'Donor'
      end
    end
  end

  describe '#name' do
    context 'with a name present' do
      before { @donor_account.update!(name: 'Bob') }

      it 'creates a contact with a fallback name' do
        expect(@donor_account.name).to eq 'Bob'
      end
    end

    context 'with a blank name' do
      before { @donor_account.update!(name: '') }

      it 'creates a contact with a fallback name' do
        expect(@donor_account.name).to eq 'Donor'
      end
    end
  end

  describe '#merge' do
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
      expect(winner.total_donations).to eq(12.99 * 2)
      expect(winner.last_donation_date).to eq Date.today
      expect(winner.first_donation_date).to eq Date.yesterday
      expect(winner.donations.to_set).to eq([donation1, donation2].to_set)
      expect(winner.master_person_donor_accounts.to_a).to eq [mpda]
      expect(winner.contact_donor_accounts.to_a).to eq [contact_donor_account]
    end
  end

  describe '.filter' do
    let!(:account_list) { create(:account_list) }

    context 'wildcard_search' do
      let!(:random_account) { create(:donor_account) }

      context 'account_number starts with' do
        let!(:donor_account) { create(:donor_account, account_number: '1234') }

        it 'returns donor_account' do
          expect(described_class.filter(account_list, wildcard_search: '12')).to eq([donor_account])
        end
      end

      context 'account_number does not start with' do
        let!(:donor_account) { create(:donor_account, account_number: '1234') }

        it 'returns donor_accounts' do
          expect(described_class.filter(account_list, wildcard_search: '34')).to eq([donor_account])
        end
      end

      context 'donor account name contains' do
        let!(:donor_account) { create(:donor_account, name: 'abcd') }

        it 'returns donor_account' do
          expect(described_class.filter(account_list, wildcard_search: 'bc')).to eq([donor_account])
        end
      end

      context 'donor account name does not contain' do
        let!(:donor_account) { create(:donor_account, name: 'abcd') }

        it 'returns no donor_accounts' do
          expect(described_class.filter(account_list, wildcard_search: 'def')).to be_empty
        end
      end

      context 'contact name contains case insensitively' do
        let!(:contact) { create(:contact, name: 'random name', account_list: account_list) }
        let!(:donor_account) { create(:donor_account, account_number: '1234', contacts: [contact]) }

        it 'returns donor_account' do
          expect(described_class.filter(account_list, wildcard_search: 'Dom Nam')).to eq([donor_account])
        end
      end

      context "name on contact belonging to another user's account list" do
        let!(:contact) { create(:contact, name: 'random name', account_list: create(:account_list)) }
        let!(:donor_account) { create(:donor_account, account_number: '1234', contacts: [contact]) }

        it 'returns no donor_accounts' do
          expect(described_class.filter(account_list, wildcard_search: 'Dom Nam')).to eq([])
        end
      end
    end

    context 'not wildcard_search' do
      let!(:donor_account) { create(:donor_account, account_number: '1234') }

      it 'returns donor_account' do
        expect(described_class.filter(account_list, account_number: donor_account.account_number)).to eq([donor_account])
      end
    end
  end

  context 'by_wildcard_search' do
    let(:account_list) { create(:account_list) }
    let!(:donor_account) { create(:donor_account, account_number: '1234') }

    it 'can be called directly' do
      expect(described_class.by_wildcard_search(account_list, '12')).to eq([donor_account])
    end
  end
end
