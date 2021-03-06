FactoryBot.define do
  factory :facebook_account, class: 'Person::FacebookAccount' do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.user_name("#{first_name} #{last_name}") }
    association :person
    sequence(:remote_id, 1)
    token 'TokenString'
    token_expires_at { 1.day.from_now }
  end
end
