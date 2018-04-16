FactoryGirl.define do
  factory :person do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    association :master_person

    factory :person_with_email do
      after(:build) do |person|
        email_address = "#{person.first_name.downcase}@example.com"
        create(:email_address, primary: true, email: email_address, person: person)
      end
    end
  end
end
