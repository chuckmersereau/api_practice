FactoryGirl.define do
  factory :contact_notes_log do
    association :contact
    recorded_on '2016-11-30 14:20:20 -0500'
    notes 'Notes'
  end
end
