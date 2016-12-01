FactoryGirl.define do
  factory :appeal_contact do
    association :appeal
    association :contact
  end
end
