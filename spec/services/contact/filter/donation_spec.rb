require 'rails_helper'

RSpec.describe Contact::Filter::Donation do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id, name: 'Contact 1') }
  let!(:donor_account_one) { create(:donor_account) }
  let!(:designation_account_one) { create(:designation_account) }
  let!(:donation_one) do
    create(:donation, donor_account: donor_account_one, designation_account: designation_account_one)
  end

  let!(:contact_two) { create(:contact, account_list_id: account_list.id, name: 'Contact 2') }
  let!(:donor_account_two) { create(:donor_account) }
  let!(:designation_account_two) { create(:designation_account) }
  let!(:donation_two) do
    create(:donation, donor_account: donor_account_two, designation_account: designation_account_two)
  end
  let!(:donation_three) do
    create(:donation, donor_account: donor_account_two, designation_account: designation_account_two)
  end

  let!(:contact_three) { create(:contact, account_list_id: account_list.id, name: 'Contact 3') }
  let!(:contact_four) { create(:contact, account_list_id: account_list.id, name: 'Contact 4') }

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
                                                                name: :donation,
                                                                options: [
                                                                  { name: '-- Any --', id: '', placeholder: 'None' },
                                                                  { name: 'No Gifts', id: 'none' },
                                                                  { name: 'One or More Gifts', id: 'one' },
                                                                  { name: 'First Gift', id: 'first' },
                                                                  { name: 'Last Gift', id: 'last' }
                                                                ],
                                                                parent: 'Gift Details',
                                                                title: 'Gift Options',
                                                                type: 'multiselect')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { donation: [''] }, nil)).to eq(nil)
      end
    end

    context 'filter by no gifts' do
      it 'returns only contacts that have never given a donation' do
        expect(
          described_class.query(contacts, { donation: 'none' }, [account_list]).to_a
        ).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by one or more gifts' do
      it 'returns only contacts that have given at least one gift' do
        expect(
          described_class.query(contacts, { donation: 'one' }, [account_list]).to_a
        ).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by first gift' do
      it 'returns only contacts that have given a first gift' do
        expect(
          described_class.query(contacts, { donation: 'first' }, [account_list]).to_a
        ).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by last gift' do
      it 'returns only contacts that have given a last gift' do
        expect(
          described_class.query(contacts, { donation: 'last' }, [account_list]).to_a
        ).to match_array [contact_one, contact_two]
      end
    end

    context 'filter by no gift and gift date' do
      it 'currently is expected to return no contacts' do
        expect(
          Contact::Filterer.new(
            donation: 'none',
            donation_date: Range.new(2.years.ago.to_datetime, 6.months.ago.to_datetime)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to match_array [contact_two, contact_three, contact_four]
        expect(
          Contact::Filterer.new(
            donation: 'none',
            donation_date: Range.new(2.weeks.ago.to_datetime, 1.day.ago.to_datetime)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to match_array [contact_one, contact_three, contact_four]
      end
    end

    context 'filter by one gift and gift date' do
      it 'returns only contacts that have given at least one gift within the dates specified' do
        expect(
          Contact::Filterer.new(
            donation: 'one',
            donation_date: Range.new(2.years.ago, 6.months.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq [contact_one]
        expect(
          Contact::Filterer.new(
            donation: ['one'],
            donation_date: Range.new(2.weeks.ago, 1.day.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq [contact_two]
      end
    end

    context 'filter by first gift and gift date' do
      it 'returns only contacts that have given a first gift within the dates specified' do
        expect(
          Contact::Filterer.new(
            donation: 'first',
            donation_date: Range.new(2.years.ago, 6.months.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq [contact_one]
        expect(
          Contact::Filterer.new(
            donation: 'first',
            donation_date: Range.new(2.weeks.ago, 1.day.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq []
      end
    end

    context 'filter by last gift and gift date' do
      it 'returns only contacts that have given a last gift within the dates specified' do
        expect(
          Contact::Filterer.new(
            donation: 'last',
            donation_date: Range.new(2.years.ago, 6.months.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq [contact_one]
        expect(
          Contact::Filterer.new(
            donation: 'last',
            donation_date: Range.new(2.weeks.ago, 1.day.ago)
          ).filter(scope: contacts, account_lists: [account_list]).to_a
        ).to eq [contact_two]
      end
    end

    context 'donations to designations outside of the specified account_list' do
      let!(:account_list_two) { create(:account_list) }
      let!(:donor_account_three) { create(:donor_account) }
      let!(:designation_account_three) { create(:designation_account) }
      let!(:donation_three) do
        create(:donation, donor_account: donor_account_three, designation_account: designation_account_three)
      end

      before do
        account_list_two.designation_accounts << designation_account_three
        contact_three.donor_accounts << donor_account_three
      end

      context 'filter by no gifts' do
        it 'returns only contacts that have never given a donation' do
          expect(
            described_class.query(contacts, { donation: 'none' }, [account_list]).to_a
          ).to match_array [contact_three, contact_four]
        end
      end
    end

    context 'contact has donor_account with donations and donor_account with no donations' do
      before do
        contact_three.donor_accounts << donor_account_one
        contact_three.donor_accounts << create(:donor_account)
      end

      context 'filter by no gifts' do
        it 'returns only contacts that have never given a donation' do
          expect(
            described_class.query(contacts, { donation: 'none' }, [account_list]).to_a
          ).to match_array [contact_four]
        end
      end
    end
  end
end
