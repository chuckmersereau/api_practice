FactoryGirl.define do
  factory :user_coach, class: 'User::Coach' do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
end
