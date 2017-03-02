require 'faker'

FactoryGirl.define do
  factory :contact do
    account_list
    locale 'en'
    name { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" }
    notes 'Test Note.'
    pledge_amount 100
    pledge_frequency 1
    pledge_start_date { 35.days.ago }
    status 'Partner - Financial'
    uuid { SecureRandom.uuid }

    factory :contact_with_person do
      after(:create) do |contact, evaluator|
        create(:person, contacts: [contact], first_name: evaluator.name, last_name: '')
      end
    end

    trait :with_tags do
      after(:create) { |contact| contact.update_attributes(tag_list: 'one, two') }
    end
  end
end
