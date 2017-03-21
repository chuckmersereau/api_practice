FactoryGirl.define do
  factory :address do
    association :addressable, factory: :contact
    association :master_address
    city 'Fremont'
    country 'United States'
    end_date '2012-02-19'
    location 'Home'
    postal_code '94539'
    primary_mailing_address false
    start_date '2012-02-19'
    state 'CA'
    street '123 Somewhere St'
    valid_values false
  end
end
