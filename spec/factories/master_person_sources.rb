FactoryGirl.define do
  factory :master_person_source do
    association :master_person
    association :organization
    remote_id 'MyString'
  end
end
