require 'rails_helper'

# Note, the Contact spec has a number of cases for contact merging as well
describe ContactMerge do
  let(:account_list) { create(:account_list) }

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

  it 'transfers pledges' do
    winner = create(:contact, account_list: account_list)
    loser = create(:contact, account_list: account_list)
    appeal = create(:appeal, account_list: account_list)
    appeal.contacts << loser
    pledge = create(:pledge, contact: loser, appeal: appeal)

    winner.merge(loser)

    expect(appeal.contacts.reload).to include winner
    expect(pledge.reload.contact).to eq winner
  end

  it 'marks loser addresses as not primary' do
    winner = create(:contact)
    loser = create(:contact)
    create(:address, primary_mailing_address: true, addressable: winner, street: '1 Test Road')
    loser_address = create(:address, primary_mailing_address: true, addressable: loser, street: '2 Test Road')
    winner.merge(loser)
    winner.reload
    expect(winner.addresses.find(loser_address.id).primary_mailing_address).to eq false
  end

  it 'removes the DuplicateRecordPair' do
    account_list = create(:account_list)
    winner = create(:contact, account_list: account_list)
    loser = create(:contact, account_list: account_list)
    duplicate_record_pair = DuplicateRecordPair.create!(record_one: winner, record_two: loser, account_list: account_list, reason: 'Testing')
    DuplicateRecordPair.new(record_one_id: winner.id, record_one_type: 'Person', record_two_id: loser.id,
                            record_two_type: 'Contact', account_list: account_list, reason: 'Testing').save(validate: false)
    expect { winner.merge(loser) }.to change { DuplicateRecordPair.count }.from(2).to(1)
    expect(DuplicateRecordPair.exists?(duplicate_record_pair.id)).to eq(false)
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
