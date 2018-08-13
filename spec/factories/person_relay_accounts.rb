FactoryBot.define do
  factory :relay_account, class: Person::RelayAccount do
    association :person
    remote_id { SecureRandom.uuid }
    relay_remote_id { SecureRandom.uuid }
    first_name 'MyString'
    last_name 'MyString'
    email 'MyString'
    designation 'MyString'
    employee_id 'MyString'
    username 'MyString'
  end
end
