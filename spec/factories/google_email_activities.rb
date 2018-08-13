FactoryBot.define do
  factory :google_email_activity do
    association :google_email
    association :activity
  end
end
