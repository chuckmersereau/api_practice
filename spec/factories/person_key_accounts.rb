# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :key_account, class: 'Person::KeyAccount' do
    association :person
    remote_id { Faker::Code.asin }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
  end
end
