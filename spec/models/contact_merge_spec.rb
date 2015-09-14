require 'spec_helper'

# Note, the Contact spec has a number of cases for contact merging as well
describe ContactMerge do
  it 'combines the send_newsletter field' do
    winner = create(:contact, send_newsletter: 'Email')
    loser = create(:contact, send_newsletter: 'Physical')
    winner.merge(loser)
    expect(winner.reload.send_newsletter).to eq 'Both'
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
