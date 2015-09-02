# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :person do
    first_name 'John'
    last_name 'Smith'
    association :master_person

    factory :person_with_email do
      after(:build) do |person|
        email = create(:email_address, primary: true, email: 'john@example.com')
        person.email_addresses << email
      end
    end
  end
end
