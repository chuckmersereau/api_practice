# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :key_account, class: 'Person::KeyAccount' do
    association :person
    remote_id 'MyString'
    first_name 'MyString'
    last_name 'MyString'
    email 'MyString'
  end
end
