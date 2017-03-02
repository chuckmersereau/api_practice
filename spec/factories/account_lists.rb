FactoryGirl.define do
  factory :account_list do
    name { Faker::Company.name }
    currency 'USD'
    home_country 'United States'
    monthly_goal { rand(10_000) }
    tester false
  end
end
