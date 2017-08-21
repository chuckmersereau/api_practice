FactoryGirl.define do
  factory :duplicate_record_pair do
    association :account_list
    record_one do
      create(:contact, account_list: account_list)
    end
    record_two do
      create(:contact, account_list: account_list)
    end
    reason 'Just testing'
  end
end
