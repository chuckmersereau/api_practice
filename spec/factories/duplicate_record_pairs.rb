FactoryBot.define do
  factory :duplicate_contacts_pair, class: 'DuplicateRecordPair' do
    association :account_list
    reason 'Just testing'
    record_one do
      create(:contact, account_list: account_list)
    end
    record_two do
      create(:contact, account_list: account_list)
    end
  end

  factory :duplicate_people_pair, class: 'DuplicateRecordPair' do
    association :account_list
    reason 'Just testing'
    record_one do
      create(:person).tap do |person|
        create(:contact, account_list: account_list)
        account_list.reload.contacts.first.people << person
      end
    end
    record_two do
      create(:person).tap do |person|
        account_list.contacts.first.people << person
      end
    end
  end
end
