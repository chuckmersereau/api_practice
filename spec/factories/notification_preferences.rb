FactoryBot.define do
  factory :notification_preference do
    association :notification_type
    association :account_list
    email { true }
  end
end
