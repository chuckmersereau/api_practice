FactoryBot.define do
  factory :user_option, class: 'User::Option' do
    sequence(:key) { |n| "key_#{n}" }
    value { Faker::Hipster.word }
    user
  end
end
