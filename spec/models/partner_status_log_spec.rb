require 'rails_helper'

describe PartnerStatusLog, versioning: true do
  subject { create(:partner_status_log) }

  it 'gets added to track status and pledge details at most once per day' do
    contact = nil
    travel_to Date.new(2015, 12, 18) do
      contact = create(:contact, status: 'Ask in Future', pledge_amount: nil)
    end

    travel_to Date.new(2015, 12, 19) do
      expect do
        contact.update(status: 'Partner - Financial')
        contact.update(pledge_amount: 200)
      end.to change(PartnerStatusLog, :count).by(1)
    end

    expect(contact.status_on_date(Date.new(2015, 12, 18))).to eq 'Ask in Future'
  end

  describe '#pledge_currency' do
    before { subject.pledge_currency = 'USD' }

    it 'returns pledge_currency' do
      expect(subject.pledge_currency).to eq 'USD'
    end

    context 'pledge_currency is nil' do
      before do
        subject.pledge_currency = nil
        subject.contact.update_attribute(:pledge_currency, 'USD')
      end

      it 'returns pledge_currency' do
        expect(subject.pledge_currency).to eq 'USD'
      end
    end
  end
end
