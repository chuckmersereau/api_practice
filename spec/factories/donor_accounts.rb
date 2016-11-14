# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :donor_account do
    association :organization
    account_number 'MyString'
    name 'MyString'
    total_donations 3
    last_donation_date Date.today
    first_donation_date Date.today
    donor_type 'Type'
    contact_ids []
  end
end
