FactoryBot.define do
  factory :linkedin_account, class: Person::LinkedinAccount do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    public_url 'http://example.com/username1'
    authenticated true
    sequence(:remote_id, &:to_s)
    association :person
    valid_token true
    token 'MyString'
    secret 'MyString'
    token_expires_at { 1.day.from_now }
  end
end
