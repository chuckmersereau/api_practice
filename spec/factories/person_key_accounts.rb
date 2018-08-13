FactoryBot.define do
  factory :key_account, class: 'Person::KeyAccount' do
    association :person
    sequence(:remote_id) { |n| n }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
  end
end
