require 'rails_helper'

RSpec.describe Contact::Filter::DonationDate do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account_one) { create(:donor_account) }
  let!(:designation_account_one) { create(:designation_account) }
  let!(:donation_one) do
    create(:donation, donor_account: donor_account_one, designation_account: designation_account_one)
  end

  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account_two) { create(:donor_account) }
  let!(:designation_account_two) { create(:designation_account) }
  let!(:donation_two) do
    create(:donation, donor_account: donor_account_two, designation_account: designation_account_two)
  end

  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account_three) { create(:donor_account) }
  let!(:donation_three) do
    create(:donation, donor_account: donor_account_three, designation_account_id: nil)
  end

  before do
    account_list.designation_accounts << designation_account_one
    account_list.designation_accounts << designation_account_two
    contact_one.donor_accounts << donor_account_one
    contact_two.donor_accounts << donor_account_two
    donation_one.update(donation_date: 1.month.ago)
    donation_two.update(donation_date: 1.month.from_now)
    donation_three.update(donation_date: 1.month.from_now)
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list]).except(:options)).to include(
        default_selection: '',
        multiple: false,
        name: :donation_date,
        parent: 'Gift Details',
        title: 'Gift Date',
        type: 'daterange'
      )
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_date: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_date: { wut: '???', hey: 'yo' } }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation_date: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by end and start date' do
      it 'returns only contacts with a donation after the start date and before the end date' do
        options = { donation_date: Range.new(1.year.ago, 1.year.from_now) }
        result = described_class.query(contacts, options, [account_list]).to_a

        expect(result).to match_array [contact_one, contact_two]

        options = { donation_date: Range.new(1.day.ago, 2.months.from_now) }
        result = described_class.query(contacts, options, [account_list]).to_a

        expect(result).to eq [contact_two]
      end
    end
  end
end
