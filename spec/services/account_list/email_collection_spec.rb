require 'rails_helper'

describe AccountList::EmailCollection do
  let!(:account_list) { create(:account_list) }

  it 'initializes' do
    expect(AccountList::EmailCollection.new(account_list)).to be_a(AccountList::EmailCollection)
  end

  describe '#grouped_by_email' do
    let!(:contact_1) { create(:contact_with_person, account_list: account_list).reload }
    let!(:person_1) { contact_1.primary_person }
    let!(:email_address_1) { create(:email_address, person: person_1) }

    let!(:contact_2) { create(:contact_with_person, account_list: account_list).reload }
    let!(:person_2) { contact_2.primary_person }
    let!(:person_3) { contact_2.spouse = create(:person) }
    let!(:email_address_2) { create(:email_address, person: person_2) }
    let!(:email_address_3) { create(:email_address, email: " #{email_address_2.email.upcase} ", person: person_3) }

    it 'normalizes and groups the data by emails' do
      expect(AccountList::EmailCollection.new(account_list).grouped_by_email).to eq(email_address_1.email => [{ contact_id: contact_1.id, person_id: person_1.id, email: email_address_1.email }],
                                                                                    email_address_2.email => [{ contact_id: contact_2.id, person_id: person_2.id, email: email_address_2.email },
                                                                                                              { contact_id: contact_2.id, person_id: person_3.id, email: email_address_3.email }])
    end
  end
end
