FactoryGirl.define do
  factory :facebook_account, class: 'Person::FacebookAccount' do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.user_name }
    association :person
    sequence(:remote_id, &:to_s)
    token 'TokenString'
    token_expires_at { 1.day.from_now }
  end
end
