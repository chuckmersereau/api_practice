FactoryGirl.define do
  factory :email_address do
    sequence(:email) { |n| "foo#{n}@example.com" }
    primary false
  end
end
