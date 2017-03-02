FactoryGirl.define do
  factory :email_address do
    historic false
    location 'home'
    primary false
    sequence(:email) { |n| "foo-#{n}@example.com" }
  end
end
