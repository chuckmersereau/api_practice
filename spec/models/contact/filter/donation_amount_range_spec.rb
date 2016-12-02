require 'spec_helper'

RSpec.describe Contact::Filter::DonationAmountRange do
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
      expect(described_class.config(account_list)).to include(default_selection: '',
                                                              multiple: false,
                                                              name: :donation_amount_range,
                                                              options: [{ name: 'Gift Amount Higher Than or Equal To', id: 'min', placeholder: 0 },
                                                                        { name: 'Gift Amount Less Than or Equal To', id: 'max', placeholder: 4444.33 }],
                                                              parent: 'Gift Details',
                                                              title: 'Gift Amount Range',
                                                              type: 'text')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount_range: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount_range: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount_range: [''] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_amount_range: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by amount min' do
      it 'returns only contacts that have given the at least the min amount' do
        expect(described_class.query(contacts, { donation_amount_range: { min: '10' } }, account_list).to_a).to match_array [contact_two]
      end
    end

    context 'filter by amount max' do
      it 'returns only contacts that have given no more than the max amount' do
        expect(described_class.query(contacts, { donation_amount_range: { max: '13' } }, account_list).to_a).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by amount min and max' do
      it 'returns only contacts that have given gifts within the min and max amounts' do
        expect(described_class.query(contacts, { donation_amount_range: { min: '10', max: '13' } }, account_list).to_a).to match_array [contact_two]
      end
    end
  end
end
