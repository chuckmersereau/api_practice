FactoryGirl.define do
  factory :phone_number do
    association :person
    number '+12134567890'
    country_code 'MyString'
    location 'mobile'
    primary false
  end
end
