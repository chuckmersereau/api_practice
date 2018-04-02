require 'rails_helper'

RSpec.describe Contact::Filter::DonationAmountRange do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list: account_list) }
  let!(:contact_two) { create(:contact, account_list: account_list) }
  let!(:contact_three) { create(:contact, account_list: account_list) }
  let!(:contact_four) { create(:contact, account_list: account_list) }

  let!(:donor_account_one) { create(:donor_account, contacts: [contact_one]) }
  let!(:donor_account_two) { create(:donor_account, contacts: [contact_two]) }
  let!(:donor_account_three) { create(:donor_account, contacts: [contact_three]) }
  let!(:donor_account_four) { create(:donor_account, contacts: [contact_four]) }

  let!(:designation_account_one) { create(:designation_account, account_lists: [account_list]) }
  let!(:designation_account_two) { create(:designation_account, account_lists: [account_list]) }

  let!(:donation_one) do
    create(:donation, donor_account: donor_account_one, designation_account: designation_account_one, amount: 12.34)
  end
  let!(:donation_two) do
    create(:donation, donor_account: donor_account_two, designation_account: designation_account_one, amount: 4444.33)
  end
  let!(:donation_three) do
    create(:donation, donor_account: donor_account_three, designation_account: designation_account_two, amount: 8.31)
  end
  let!(:donation_four) do
    create(:donation, donor_account: donor_account_four, designation_account_id: nil, amount: 12.00)
  end

  describe '#config' do
    it 'returns expected config' do
      options = [{ name: 'Gift Amount Higher Than or Equal To', id: 'min', placeholder: 0 },
                 { name: 'Gift Amount Less Than or Equal To', id: 'max', placeholder: 4444.33 }]
      expect(described_class.config([account_list])).to include(default_selection: '',
                                                                multiple: false,
                                                                name: :donation_amount_range,
                                                                options: options,
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
        result = described_class.query(contacts, { donation_amount_range: { min: '10' } }, [account_list]).to_a
        expect(result).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by amount max' do
      it 'returns only contacts that have given no more than the max amount' do
        result = described_class.query(contacts, { donation_amount_range: { max: '13' } }, [account_list]).to_a
        expect(result).to match_array [contact_one, contact_three]
      end
    end

    context 'filter by amount min and max' do
      it 'returns only contacts that have given gifts within the min and max amounts' do
        result = described_class.query(contacts, { donation_amount_range: { min: '10', max: '13' } }, [account_list]).to_a
        expect(result).to match_array [contact_one]
      end
    end
  end
end
