require 'rails_helper'

RSpec.describe Contact::DupContactsMerge, type: :model do
  let(:account_list) { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact) { create(:contact, name: 'Tester', account_list: account_list) }

  describe 'initialize' do
    it 'initializes' do
      expect(
        Contact::DupContactsMerge.new(account_list: account_list, contact: contact)
      ).to be_a(Contact::DupContactsMerge)
    end
  end

  describe '#find_duplicates' do
    context 'contacts have the same name' do
      let!(:contact_one) { contact }
      let!(:contact_two) { create(:contact, name: 'Tester', account_list: account_list) }
      let!(:contact_three) { create(:contact, name: 'Tester', account_list: account_list) }
      let!(:contact_four) { create(:contact, name: 'Someone Else', account_list: account_list) }

      before do
        contact_one.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_two.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_three.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_four.people << build(:person, first_name: 'Fname', last_name: 'Lname')
      end

      subject { Contact::DupContactsMerge.new(account_list: account_list, contact: contact).find_duplicates }

      context 'contacts do not share donor accounts and do not share addresses' do
        it 'does not find any duplicate contact' do
          expect(subject).to eq([])
        end
      end

      context 'contacts share donor accounts' do
        before do
          account_list.designation_accounts << designation_account
          contact_one.donor_accounts << donor_account
          contact_two.donor_accounts << donor_account
          contact_three.donor_accounts << create(:donor_account)
          contact_four.donor_accounts << donor_account
        end

        it 'finds a duplicate contact' do
          expect(subject).to eq([contact_two])
        end
      end

      context 'contacts share addresses' do
        let(:master_address_id_1) { SecureRandom.uuid }
        let(:master_address_id_2) { SecureRandom.uuid }

        before do
          contact_one.addresses << build(:address, master_address_id: master_address_id_1)
          contact_two.addresses << build(:address, master_address_id: master_address_id_1)
          contact_three.addresses << build(:address,
                                           master_address_id: master_address_id_2,
                                           city: 'Somewhere Else',
                                           postal_code: '1234asdf')
          contact_four.addresses << build(:address, master_address_id: master_address_id_1)
        end

        it 'finds a duplicate contact' do
          expect(subject).to eq([contact_two])
        end
      end
    end
  end

  describe '#merge_duplicates' do
    context 'contacts have the same name' do
      let!(:contact_one) { contact }
      let!(:contact_two) { create(:contact, name: 'Tester', account_list: account_list) }
      let!(:contact_three) { create(:contact, name: 'Tester', account_list: account_list) }
      let!(:contact_four) { create(:contact, name: 'Someone Else', account_list: account_list) }

      before do
        contact_one.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_two.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_three.people << build(:person, first_name: 'Fname', last_name: 'Lname')
        contact_four.people << build(:person, first_name: 'Fname', last_name: 'Lname')
      end

      subject { Contact::DupContactsMerge.new(account_list: account_list, contact: contact).merge_duplicates }

      context 'contacts do not share donor accounts and do not share addresses' do
        it 'does not merge contacts' do
          expect { subject }.to_not change { account_list.reload.contacts.count }.from(4)
        end
      end

      context 'contacts share donor accounts' do
        before do
          account_list.designation_accounts << designation_account
          contact_one.donor_accounts << donor_account
          contact_two.donor_accounts << donor_account
          contact_three.donor_accounts << create(:donor_account)
          contact_four.donor_accounts << donor_account
        end

        it 'merges contacts' do
          expect { subject }.to change { account_list.reload.contacts.count }.from(4).to(3)
        end

        it 'merges people' do
          expect { subject }.to change { Person.count }.from(4).to(3)
        end
      end

      context 'contacts share addresses' do
        let(:master_address_id_1) { SecureRandom.uuid }
        let(:master_address_id_2) { SecureRandom.uuid }

        before do
          contact_one.addresses << build(:address, master_address_id: master_address_id_1)
          contact_two.addresses << build(:address, master_address_id: master_address_id_1)
          contact_three.addresses << build(:address,
                                           master_address_id: master_address_id_2,
                                           city: 'Somewhere Else',
                                           postal_code: '1234asdf')
          contact_four.addresses << build(:address, master_address_id: master_address_id_1)
        end

        it 'merges contacts' do
          expect { subject }.to change { account_list.reload.contacts.count }.from(4).to(3)
        end

        it 'merges addresses' do
          expect { subject }.to change { Address.count }.from(4).to(3)
        end
      end
    end
  end
end
