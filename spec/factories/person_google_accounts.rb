FactoryBot.define do
  factory :google_account, class: 'Person::GoogleAccount' do
    remote_id 'MyString'
    association :person
    token 'MyString'
    refresh_token 'MyString'
    expires_at { 1.hour.from_now }
    sequence(:email) { |n| "foo#{n}@example.com" }
    valid_token true
  end
end
