require 'rails_helper'

RSpec.describe Contact::SuggestedChangesUpdater, type: :model do
  include ContactStatusSuggesterSpecHelpers

  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account) }
  let(:designation_account) { create(:designation_account) }
  let(:service) { Contact::SuggestedChangesUpdater.new(contact: contact) }

  subject { service.update_status_suggestions }

  before do
    travel_to Time.current.beginning_of_year
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
    contact.donations.each(&:destroy!)
  end

  after do
    travel_back
  end

  it 'initializes' do
    expect(service).to be_a Contact::SuggestedChangesUpdater
    expect(service.contact).to eq contact
  end

  # Run the following specs for each pledge frequency
  Contact.pledge_frequencies.keys.sort.each do |pledge_frequency|
    describe '#update_status_suggestions' do
      context 'suggested status does not match current status' do
        before do
          create_donations_to_match_frequency(pledge_frequency)
          contact.update_columns(status: nil,
                                 pledge_frequency: nil,
                                 pledge_amount: nil,
                                 pledge_currency: nil)
        end

        it 'does not change updated_at' do
          expect { subject }.to_not change { contact.reload.updated_at }
        end

        it 'updates suggested_changes' do
          subject
          expect(contact.suggested_changes[:pledge_frequency]).to eq pledge_frequency
          expect(contact.status_valid).to eq false
          expect(contact.suggested_changes[:status]).to eq 'Partner - Financial'
          expect(contact.suggested_changes[:pledge_amount]).to eq 50
          expect(contact.suggested_changes[:pledge_currency]).to eq 'CAD'
        end
      end

      context 'suggested status matches current status' do
        before do
          create_donations_to_match_frequency(pledge_frequency)
          contact.update_columns(status: 'Partner - Financial',
                                 pledge_frequency: pledge_frequency,
                                 pledge_amount: 50,
                                 pledge_currency: 'CAD')
        end

        it 'does not change updated_at' do
          expect { subject }.to_not change { contact.reload.updated_at }
        end

        it 'updates suggested_changes' do
          subject
          expect(contact.suggested_changes.keys.include?(:pledge_frequency)).to eq false
          expect(contact.status_valid).to eq true
          expect(contact.suggested_changes.keys.include?(:status)).to eq false
          expect(contact.suggested_changes.keys.include?(:pledge_amount)).to eq false
          expect(contact.suggested_changes.keys.include?(:pledge_currency)).to eq false
        end
      end

      context 'contact has status that we do not support suggesting' do
        before do
          contact.update_columns(status: 'Partner - Prayer')
        end

        it 'does not suggest a nil status' do
          subject
          expect(contact.suggested_changes.keys.include?(:status)).to eq false
        end
      end

      context 'contact has nil pledge_currency' do
        before do
          contact.update_columns(status: 'Partner - Prayer', pledge_amount: nil, pledge_frequency: nil, pledge_currency: 'CAD')
        end

        it 'does not suggest a nil pledge_currency' do
          subject
          expect(contact.suggested_changes.keys.include?(:pledge_currency)).to eq false
        end
      end

      context 'pledge_amount is 0' do
        before do
          contact.update_columns(status: 'Partner - Prayer', pledge_amount: 0, pledge_frequency: nil, pledge_currency: nil)
        end

        it 'does not suggest a pledge_amount' do
          subject
          expect(contact.suggested_changes.keys.include?(:pledge_amount)).to eq false
        end
      end
    end
  end

  context 'pledge_frequency is 0' do
    before do
      contact.update_columns(status: 'Partner - Prayer', pledge_amount: nil, pledge_frequency: 0, pledge_currency: nil)
    end

    it 'does not suggest a pledge_frequency' do
      subject
      expect(contact.suggested_changes.keys.include?(:pledge_frequency)).to eq false
    end
  end

  context 'suggesting changes again after the contact has been updated' do
    before do
      create_donations_to_match_frequency(1.0)
      contact.update_columns(status: nil,
                             pledge_frequency: nil,
                             pledge_amount: nil,
                             pledge_currency: nil)
    end

    it 'does not suggest the same change after it has been applied to the contact' do
      service.update_status_suggestions
      expect(contact.reload.suggested_changes).to be_present
      contact.update!(contact.reload.suggested_changes)
      service.update_status_suggestions
      expect(contact.reload.suggested_changes).to be_blank
    end
  end

  describe '#status_confirmed_recently?' do
    it 'updates suggested_changes if status_confirmed_at is nil' do
      contact.update!(status_confirmed_at: nil)
      expect { service.update_status_suggestions }.to change { contact.reload.suggested_changes }.from({})
    end

    it 'does not update suggested_changes if status_confirmed_at is less than a year ago' do
      contact.update!(status_confirmed_at: 11.months.ago)
      expect { service.update_status_suggestions }.to_not change { contact.reload.suggested_changes }.from({})
    end

    it 'updates suggested_changes if status_confirmed_at is more than a year ago' do
      contact.update!(status_confirmed_at: 13.months.ago)
      expect { service.update_status_suggestions }.to change { contact.reload.suggested_changes }.from({})
    end
  end

  describe 'the financial partner giving extra' do
    before do
      contact.update_columns(status: 'Partner - Financial',
                             status_valid: true,
                             pledge_frequency: nil,
                             pledge_amount: nil,
                             pledge_currency: nil)
      create_donations_to_match_frequency(1.0)
    end

    it 'should NOT be suggested for "Partner - Special"' do
      service.update_status_suggestions
      expect(contact.suggested_changes.keys.include?(:status)).to be false
    end
  end

  describe 'the financial partner misses one month' do
    before do
      contact.update_columns(status: 'Partner - Financial',
                             status_valid: true,
                             pledge_frequency: nil,
                             pledge_amount: nil,
                             pledge_currency: nil)
      create_donations_with_missing_month(1.0)
    end

    it 'should NOT be suggested for "Partner - Special"' do
      service.update_status_suggestions
      expect(contact.suggested_changes.keys.include?(:status)).to be false
    end
  end
end
