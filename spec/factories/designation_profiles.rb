FactoryGirl.define do
  factory :designation_profile do
    remote_id 1
    name 'foo'
    association :organization
    association :user
  end
end
