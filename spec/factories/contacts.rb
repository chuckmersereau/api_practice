# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    account_list
    name 'Doe, John'
    status 'Partner - Financial'
    pledge_amount 100
    pledge_frequency 1
    pledge_start_date { 35.days.ago }
    notes 'Test Note.'
    trait :with_tags do
      after(:create) { |contact| contact.update_attributes(tag_list: 'one, two') }
    end
  end
end
