require 'spec_helper'

describe ContactNotesLog, versioning: true do
  it 'tracks notes at most once per day in separate table from partner status' do
    contact = nil
    travel_to Date.new(2015, 12, 19) do
      contact = create(:contact, notes: 'old')
    end
    travel_to Date.new(2015, 12, 20) do
      expect do
        contact.update(notes: 'changed')
      end.to change(PartnerStatusLog, :count).by(0)
        .and change(ContactNotesLog, :count).by(1)
    end

    expect(contact.notes_on_date(Date.new(2015, 12, 19))).to eq 'old'
  end
end
