# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :twitter_account, class: 'Person::TwitterAccount' do
    screen_name { Faker::Internet.user_name }
    association :person
    sequence(:remote_id, &:to_s)
    token 'MyString'
    secret 'MyString'
  end
end
