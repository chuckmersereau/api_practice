require 'rails_helper'

RSpec.describe Contact::StatusSuggester, type: :model do
  include ContactStatusSuggesterSpecHelpers

  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account) }
  let(:designation_account) { create(:designation_account) }
  let(:service) { Contact::StatusSuggester.new(contact: contact) }

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
    expect(service).to be_a Contact::StatusSuggester
    expect(service.contact).to eq contact
  end

  # Run the following specs for each pledge frequency
  Contact.pledge_frequencies.keys.sort.each do |pledge_frequency|
    pledge_frequency_in_days = (pledge_frequency * 30).round

    context 'no donations' do
      before { contact.donations.each(&:destroy!) }

      it 'cannot make suggestions' do
        expect(service.suggested_pledge_frequency).to eq nil
        expect(service.suggested_pledge_amount).to eq nil
        expect(service.suggested_pledge_currency).to eq nil
        expect(service.suggested_status).to eq nil
        expect(service.contact_has_stopped_giving?).to eq false
      end
    end

    context 'perfectly consistent donations' do
      before { create_donations_to_match_frequency(pledge_frequency) }

      it "makes accurate suggestions for donations at pledge frequency #{pledge_frequency}" do
        expect(service.suggested_pledge_frequency).to eq pledge_frequency
        expect(service.suggested_pledge_amount).to eq 50
        expect(service.suggested_pledge_currency).to eq 'CAD'
        expect(service.suggested_status).to eq 'Partner - Financial'
        expect(service.contact_has_stopped_giving?).to eq false
      end
    end

    context 'only one donation is late' do
      before do
        create_donations_to_match_frequency(pledge_frequency) # Create the consistent donations
        # Make one donation late by about half the period we're looking for
        contact.donations.second.tap do |donation|
          donation.update donation_date: donation.donation_date + (pledge_frequency_in_days / 2).round.days
        end
      end

      it "makes accurate suggestions for donations at pledge frequency #{pledge_frequency}" do
        expect(service.suggested_pledge_frequency).to eq pledge_frequency
        expect(service.suggested_pledge_amount).to eq 50
        expect(service.suggested_pledge_currency).to eq 'CAD'
        expect(service.suggested_status).to eq 'Partner - Financial'
        expect(service.contact_has_stopped_giving?).to eq false
      end
    end

    context 'less donations than the look back period' do
      before do
        # Skip the one time donation, because it will mess up this strategy
        create_donations_to_match_frequency(pledge_frequency, one_time: false)
      end

      it "makes accurate suggestions for donations at pledge frequency #{pledge_frequency}" do
        while contact.donations.count > 2
          contact.donations.last.destroy
          expect(service.suggested_pledge_frequency).to eq pledge_frequency
          expect(service.suggested_pledge_amount).to eq 50
          expect(service.suggested_pledge_currency).to eq 'CAD'
          expect(service.suggested_status).to eq 'Partner - Financial'
          expect(service.contact_has_stopped_giving?).to eq false
        end
      end
    end

    context 'partner special' do
      before do
        create(:donation, donor_account: donor_account,
                          designation_account: designation_account,
                          tendered_amount: 20,
                          donation_date: pledge_frequency_in_days.days.ago)
      end

      it "makes accurate suggestions for donations at pledge frequency #{pledge_frequency}" do
        expect(service.suggested_pledge_frequency).to eq nil
        expect(service.suggested_pledge_amount).to eq nil
        expect(service.suggested_pledge_currency).to eq nil
        expect(service.suggested_status).to eq 'Partner - Special'
        expect(service.contact_has_stopped_giving?).to eq false
      end
    end

    context 'contact was a financial partner but has now stopped giving' do
      before do
        create_donations_to_match_frequency(pledge_frequency)
        # Move all donations back by two periods, to make it seem like they have stopped giving
        Donation.all.each do |donation|
          donation.update(donation_date: donation.donation_date - (pledge_frequency_in_days * 3).days)
        end
      end

      it "makes accurate suggestions for donations at pledge frequency #{pledge_frequency}" do
        expect(service.suggested_pledge_frequency).to eq nil
        expect(service.suggested_pledge_amount).to eq nil
        expect(service.suggested_pledge_currency).to eq nil
        expect(service.suggested_status).to eq 'Partner - Special'
        expect(service.contact_has_stopped_giving?).to eq true
      end
    end
  end
end
