FactoryBot.define do
  factory :pledge do
    amount '9.99'
    amount_currency 'USD'
    expected_date { Date.today }
    account_list
    contact
  end
end
