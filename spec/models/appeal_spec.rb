require 'rails_helper'

describe Appeal do
  let(:account_list) { create(:account_list) }
  subject { create(:appeal, account_list: account_list) }
  let(:contact) { create(:contact, account_list: account_list) }

  describe '.filter' do
    context 'wildcard_search' do
      context 'name contains' do
        let!(:appeal) { create(:appeal, name: 'abcd', account_list: account_list) }
        it 'returns donor_account' do
          expect(described_class.filter(wildcard_search: 'bc')).to eq([appeal])
        end
      end
      context 'name does not contain' do
        let!(:appeal) { create(:appeal, name: 'abcd', account_list: account_list) }
        it 'returns no designation_accounts' do
          expect(described_class.filter(wildcard_search: 'def')).to be_empty
        end
      end
    end
    context 'not wildcard_search' do
      let!(:appeal) { create(:appeal, amount: 10, account_list: account_list) }
      it 'returns designation_account' do
        expect(described_class.filter(amount: 10)).to eq([appeal])
      end
    end
  end

  describe '#bulk_add_contacts' do
    let(:contact2) { create(:contact, account_list: account_list) }

    it 'bulk adds the contacts but removes duplicates first and does not create dups when run again' do
      expect do
        subject.bulk_add_contacts(contacts: [contact, contact, contact2])
      end.to change(subject.contacts, :count).from(0).to(2)

      expect do
        subject.bulk_add_contacts(contacts: [contact, contact, contact2])
      end.to_not change(subject.contacts, :count).from(2)
    end

    it 'bulk adds the contact_ids but removes duplicates first and does not create dups when run again' do
      expect do
        subject.bulk_add_contacts(contact_ids: [contact.id, contact.id, contact2.id])
      end.to change(subject.contacts, :count).from(0).to(2)

      expect do
        subject.bulk_add_contacts(contact_ids: [contact.id, contact.id, contact2.id])
      end.to_not change(subject.contacts, :count).from(2)
    end
  end

  describe '#donated?' do
    let(:donor_account) { create(:donor_account, contacts: [contact]) }
    let(:donation) { create(:donation, donor_account: donor_account, appeal: subject) }

    before do
      contact.donor_accounts << donor_account
    end

    it 'responds with false when a contact has not given' do
      expect(subject.donated?(contact)).to be_falsy
    end

    it 'responds with true when a contact has given' do
      donation
      expect(subject.donated?(contact)).to be_truthy
    end
  end

  context 'pledges related fields' do
    subject { create(:appeal) }

    let!(:processed_pledge) do
      create(
        :pledge,
        status: :processed,
        amount: 200.00,
        appeal: subject,
        created_at: Time.now.getlocal.beginning_of_day
      )
    end
    let!(:received_not_processed_pledge) do
      create(
        :pledge,
        status: :received_not_processed,
        amount: 300.00,
        appeal: subject,
        created_at: Time.now.getlocal.beginning_of_day
      )
    end
    let!(:not_received_not_processed_pledge) do
      create(
        :pledge,
        amount: 400.00,
        appeal: subject,
        created_at: Time.now.getlocal.beginning_of_day
      )
    end

    describe '#pledges_amount_total' do
      it 'returns the total amount of all pledges' do
        expect(ConvertedTotal).to receive(:new).and_call_original
        expect(subject.pledges_amount_total).to eq(900.00)
      end
    end

    describe '#pledges_amount_not_received_not_processed' do
      it 'returns the total amount of pledges that were not processed and received' do
        expect(ConvertedTotal).to receive(:new).with(
          [[not_received_not_processed_pledge.amount,
            not_received_not_processed_pledge.contact.read_attribute(:pledge_currency),
            not_received_not_processed_pledge.created_at]],
          subject.account_list.salary_currency_or_default
        ).and_call_original
        expect(subject.pledges_amount_not_received_not_processed).to eq(400.00)
      end
    end

    describe '#pledges_amount_received_not_processed' do
      it 'returns the total amount of all pledges that were received and not processed' do
        expect(ConvertedTotal).to receive(:new).with(
          [[received_not_processed_pledge.amount,
            received_not_processed_pledge.contact.read_attribute(:pledge_currency),
            received_not_processed_pledge.created_at]],
          subject.account_list.salary_currency_or_default
        ).and_call_original
        expect(subject.pledges_amount_received_not_processed).to eq(300.00)
      end
    end

    describe '#pledges_amount_processed' do
      let(:part_donation) { create(:donation, amount: 100, appeal_amount: 50, appeal: subject) }
      let(:full_donation) { create(:donation, amount: 150, appeal: subject) }
      before do
        create(:pledge_donation, pledge: processed_pledge, donation: part_donation)
        create(:pledge_donation, pledge: processed_pledge, donation: full_donation)
      end

      it 'returns the total amount of all pledges that were received and processed' do
        expect(ConvertedTotal).to receive(:new).with(
          [
            [
              part_donation.appeal_amount,
              part_donation.currency,
              part_donation.donation_date
            ], [
              full_donation.amount,
              full_donation.currency,
              full_donation.donation_date
            ]
          ],
          subject.account_list.salary_currency_or_default
        ).and_call_original
        expect(subject.pledges_amount_processed).to eq(200.00)
      end
    end
  end

  describe '#create_contact_associations' do
    subject { build(:appeal, account_list: account_list) }
    let!(:contact1) do
      create(:contact,
             account_list: account_list,
             status: 'Partner - Financial',
             send_newsletter: 'Both')
    end
    let!(:contact2) do
      create(:contact,
             account_list: account_list,
             status: 'Never Contacted',
             send_newsletter: 'Both')
    end
    let!(:contact3) do
      create(:contact,
             account_list: account_list,
             status: 'Partner - Pray',
             pledge_currency: 'NZD',
             send_newsletter: 'Both')
    end
    let!(:contact4) do
      create(:contact,
             account_list: account_list,
             status: 'Partner - Financial',
             pledge_currency: 'NZD',
             send_newsletter: 'Both')
    end

    it 'adds appeal_contacts (with a id) for contacts within inclusion filter' do
      subject.inclusion_filter = {
        status: 'Partner - Financial',
        newsletter: 'Both'
      }

      subject.save
      expect(subject.contacts).to match_array [contact1, contact4]
      expect(subject.appeal_contacts.first.id).to be_present
    end

    it 'adds excluded_appeal_contacts (with a id) for all contacts in the exclusion filters' do
      subject.inclusion_filter = {
        newsletter: 'Both'
      }

      subject.exclusion_filter = {
        status: 'Partner - Financial',
        pledge_currency: 'NZD'
      }

      subject.save
      expect(subject.contacts).to eq([contact2])
      expect(subject.excluded_contacts).to match_array([contact1, contact3, contact4])
      expect(subject.excluded_appeal_contacts.first.id).to be_present
    end

    it 'adds filter name as reason for exclusion' do
      end_date = Date.today
      start_date = end_date - 5.months
      expect(Contact::Filterer).to receive(:new).with(
        newsletter: 'Both'
      ).at_least(:once).and_call_original
      expect(Contact::Filterer).to receive(:new).with(
        status: 'Partner - Financial'
      ).once.and_call_original
      expect(Contact::Filterer).to receive(:new).with(
        pledge_currency: 'NZD'
      ).once.and_call_original
      expect(Contact::Filterer).to receive(:new).with(
        no_appeals: true
      ).once.and_call_original
      expect(Contact::Filterer).to receive(:new).with(
        gave_more_than_pledged_range: Range.new(start_date, end_date)
      ).once.and_call_original

      subject.inclusion_filter = {
        'newsletter' => 'Both'
      }

      subject.exclusion_filter = {
        'status' => 'Partner - Financial',
        'pledge_currency' => 'NZD',
        'no_appeals' => true,
        'gave_more_than_pledged_range' => "#{start_date.strftime('%Y-%m-%d')}...#{end_date.strftime('%Y-%m-%d')}"
      }

      contact.update(no_appeals: nil)

      subject.save

      excluded_appeal_contact1 = subject.excluded_appeal_contacts.find_by(contact: contact1)
      excluded_appeal_contact2 = subject.excluded_appeal_contacts.find_by(contact: contact2)
      excluded_appeal_contact3 = subject.excluded_appeal_contacts.find_by(contact: contact3)
      excluded_appeal_contact4 = subject.excluded_appeal_contacts.find_by(contact: contact4)

      expect(excluded_appeal_contact1.reasons).to eq(['status'])
      expect(excluded_appeal_contact2).to be nil
      expect(excluded_appeal_contact3.reasons).to eq(['pledge_currency'])
      expect(excluded_appeal_contact4.reasons).to match_array(%w(status pledge_currency))
    end

    it 'does not add any contacts when filters are not included' do
      subject.save
      expect(subject.appeal_contacts.count).to eq(0)
      expect(subject.excluded_appeal_contacts.count).to eq(0)
    end

    it 'successes with all front-end filters' do
      end_date = Date.today
      start_date = end_date - 5.months
      date_range = "#{start_date.strftime('%Y-%m-%d')}..#{end_date.strftime('%Y-%m-%d')}"

      contact1.update(tag_list: %w(cru))

      subject.inclusion_filter = {
        'account_list_id' => account_list.id,
        'tags' => 'asdf',
        'any_tags' => true
      }

      subject.exclusion_filter = {
        'gave_more_than_pledged_range' => date_range,
        'pledge_amount_increased_range' => date_range,
        'started_giving_range' => date_range,
        'stopped_giving_range' => "#{start_date.strftime('%Y-%m-%d')}..#{(end_date - 1.month).strftime('%Y-%m-%d')}",
        'no_appeals' => true
      }

      expect { subject.save }.to_not raise_exception
    end
  end

  describe '#destroy' do
    let(:donor_account) { create(:donor_account, contacts: [contact]) }
    let!(:donation) { create(:donation, donor_account: donor_account, appeal: subject) }

    it 'nullifies related donations' do
      subject.destroy

      expect(donation.reload.appeal_id).to be nil
    end
  end
end
