require 'rails_helper'

# Note, the Contact spec has a number of cases for contact merging as well
describe ContactMerge do
  it 'combines the send_newsletter field' do
    winner = create(:contact, send_newsletter: 'Email')
    loser = create(:contact, send_newsletter: 'Physical')
    winner.merge(loser)
    expect(winner.reload.send_newsletter).to eq 'Both'
  end

  it 'prefers a non-default greeting and envelope greeting to default' do
    winner = create(:contact, greeting: nil, envelope_greeting: nil)
    loser = create(:contact, greeting: 'Hi', envelope_greeting: 'Hello')
    winner.merge(loser)
    winner.reload
    expect(winner.greeting).to eq 'Hi'
    expect(winner.envelope_greeting).to eq 'Hello'
  end

  it 'transfers activities, but does not duplicate them' do
    winner = create(:contact)
    loser = create(:contact)
    winner.activities << create(:activity, subject: 'Random Task')
    loser.activities << create(:activity, subject: 'Random Task')
    loser.activities << create(:activity, subject: 'Random Task #2')
    winner.merge(loser)
    winner.reload
    expect(winner.activities.count).to eq(2)
  end

  context '.merged_send_newsletter' do
    it 'combines email and physical for all cases' do
      [
        ['Email', '', 'Email'],
        %w(Email Physical Both),
        [nil, 'Physical', 'Physical'],
        [nil, '', nil]
      ].each do |winner, loser, merged|
        expect(ContactMerge.merged_send_newsletter(winner, loser)).to eq merged
        expect(ContactMerge.merged_send_newsletter(loser, winner)).to eq merged
      end
    end
  end
end
