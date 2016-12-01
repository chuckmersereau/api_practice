FactoryGirl.define do
  factory :notification do
    notification_type_id 1
    cleared false
    event_date '2012-10-23 17:03:15'
    contact nil
    donation nil
  end
end
