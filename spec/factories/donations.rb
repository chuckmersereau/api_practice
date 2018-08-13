FactoryBot.define do
  factory :donation do
    sequence(:remote_id, 1) { |n| n&.to_s }
    amount '9.99'
    donation_date { Date.today }
    appeal_amount '0.00'
    association :donor_account
    association :designation_account
    motivation 'MyString'
    payment_method 'MyString'
    tendered_currency 'ZAR'
    tendered_amount '9.99'
    currency 'ZAR'
    memo 'MyText'
    payment_type 'MyString'
    channel 'MyString'
  end
end
