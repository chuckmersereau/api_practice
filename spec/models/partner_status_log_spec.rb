require 'spec_helper'

describe PartnerStatusLog, versioning: true do
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
end
