FactoryGirl.define do
  factory :twitter_account, class: 'Person::TwitterAccount' do
    screen_name { Faker::Internet.user_name }
    association :person
    sequence(:remote_id, 1)
    token 'MyString'
    secret 'MyString'
  end
end
