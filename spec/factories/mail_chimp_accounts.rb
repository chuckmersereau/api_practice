FactoryBot.define do
  factory :mail_chimp_account do
    api_key 'fake-us4'
    active false
    primary_list_id 'MyString'
    association :account_list
  end
end
