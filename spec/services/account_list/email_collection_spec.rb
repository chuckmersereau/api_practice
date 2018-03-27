require 'rails_helper'

describe AccountList::EmailCollection do
  let!(:account_list) { create(:account_list) }

  it 'initializes' do
    expect(AccountList::EmailCollection.new(account_list)).to be_a(AccountList::EmailCollection)
  end

  describe '#select_by_email' do
    let!(:contact_1) { create(:contact_with_person, account_list: account_list).reload }
    let!(:person_1) { contact_1.primary_person }
    let!(:email_address_1) { create(:email_address, person: person_1) }

    let!(:contact_2) { create(:contact_with_person, account_list: account_list).reload }
    let!(:person_2) { contact_2.primary_person }
    let!(:person_3) { contact_2.spouse = create(:person) }
    let!(:email_address_2) { create(:email_address, person: person_2) }
    let!(:email_address_3) { create(:email_address, email: " #{email_address_2.email.upcase} ", person: person_3) }
    let!(:email_address_4) { create(:email_address, person: person_2, deleted: true) }

    it 'selects the data by normalized emails without the deleted emails' do
      collection = AccountList::EmailCollection.new(account_list)

      person1_hash = { contact_id: contact_1.id, person_id: person_1.id, email: email_address_1.email }
      expect(collection.select_by_email(email_address_1.email)).to match_array([person1_hash])
      expect(collection.select_by_email(" #{email_address_1.email.upcase} ")).to match_array([person1_hash])

      person2_hash = { contact_id: contact_2.id, person_id: person_2.id, email: email_address_2.email }
      person3_hash = { contact_id: contact_2.id, person_id: person_3.id, email: email_address_3.email }
      expect(collection.select_by_email(email_address_2.email)).to match_array([person2_hash, person3_hash])
    end

    it 'handles a nil argument' do
      expect(AccountList::EmailCollection.new(account_list).select_by_email(nil)).to eq([])
    end
  end
end
