FactoryGirl.define do
  factory :google_email do
    google_email_id 1
    association :google_account
  end
end
