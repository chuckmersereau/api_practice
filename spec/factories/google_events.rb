FactoryBot.define do
  factory :google_event do
    association :activity
    association :google_integration
    google_event_id 'MyString'
    calendar_id 'cal1'
  end
end
