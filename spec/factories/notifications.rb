FactoryBot.define do
  factory :notification do
    notification_type
    cleared false
    event_date '2012-10-23 17:03:15'
    contact
    donation
  end
end
