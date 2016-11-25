# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :twitter_account, class: 'Person::TwitterAccount' do
  	person_id 1
    sequence(:remote_id, &:to_s)
    screen_name { Faker::Internet.user_name }
    token 'MyString'
    secret 'MyString'
  end
end
