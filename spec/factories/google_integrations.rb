FactoryGirl.define do
  factory :google_integration do
    calendar_integration true
    calendar_id 'cal1'
    association :account_list
    association :google_account
    email_blacklist ['bad@email.com']
  end
end
