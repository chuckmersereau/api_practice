FactoryGirl.define do
  factory :master_person_donor_account do
    association :master_person
    association :donor_account
    primary false
  end
end
