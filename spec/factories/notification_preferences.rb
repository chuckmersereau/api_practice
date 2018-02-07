FactoryGirl.define do
  factory :notification_preference do
    association :notification_type
    association :account_list
    actions ['email']
  end
end
