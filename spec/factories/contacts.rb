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
    factory :contact_with_person do
      after(:create) do |contact, evaluator|
        create_list(:person, 1, contacts: [contact], first_name: evaluator.name, last_name: '')
        create_list(:address, 1, addressable: contact, primary_mailing_address: true)
      end
    end
  end
end
