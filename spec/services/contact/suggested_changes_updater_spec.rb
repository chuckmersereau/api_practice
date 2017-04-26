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

        it 'updates status_validated_at' do
          expect { subject }.to change { contact.reload.status_validated_at }.to(Time.current)
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

        it 'updates status_validated_at' do
          expect { subject }.to change { contact.reload.status_validated_at }.to(Time.current)
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
end
