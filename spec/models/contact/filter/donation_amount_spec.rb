require 'spec_helper'

RSpec.describe Contact::Filter::DonationAmount do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account_one) { create(:donor_account) }
  let!(:designation_account_one) { create(:designation_account) }
  let!(:donation_one) { create(:donation, donor_account: donor_account_one, designation_account: designation_account_one) }

  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account_two) { create(:donor_account) }
  let!(:designation_account_two) { create(:designation_account) }
  let!(:donation_two) { create(:donation, donor_account: donor_account_two, designation_account: designation_account_two, amount: 12.34) }
  let!(:donation_three) { create(:donation, donor_account: donor_account_two, designation_account: designation_account_two, amount: 4444.33) }

  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four) { create(:contact, account_list_id: account_list.id) }

  before do
    account_list.designation_accounts << designation_account_one
    account_list.designation_accounts << designation_account_two
    contact_one.donor_accounts << donor_account_one
    contact_two.donor_accounts << donor_account_two
    donation_one.update(donation_date: 1.year.ago)
    donation_two.update(donation_date: 1.month.ago)
    donation_three.update(donation_date: 1.week.ago)
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(default_selection: '',
                                                              multiple: true,
                                                              name: :donation_amount,
                                                              options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                        { name: 9.99, id: 9.99 },
                                                                        { name: 12.34, id: 12.34 },
                                                                        { name: 4444.33, id: 4444.33 }],
                                                              parent: 'Gift Details',
                                                              title: 'Exact Gift Amount',
                                                              type: 'multiselect')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount: [''] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by amounts' do
      it 'returns only contacts that have given the exact amount' do
        expect(described_class.query(contacts, { donation_amount: ['9.99'] }, account_list).to_a).to match_array [contact_one]
      end
      it 'returns only contacts that have given multiple exact amounts' do
        expect(described_class.query(contacts, { donation_amount: ['9.99', '12.34'] }, account_list).to_a).to match_array [contact_one, contact_two]
      end
    end
  end
end
