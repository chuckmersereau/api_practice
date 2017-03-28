FactoryGirl.define do
  factory :pledge do
    amount '9.99'
    expected_date { Date.today }
    donation
    account_list
    contact
  end
end
