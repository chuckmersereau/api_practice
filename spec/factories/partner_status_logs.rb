FactoryBot.define do
  factory :partner_status_log do
    association :contact
    recorded_on '2016-11-30 14:20:20 -0500'
    status 'MyString'
    pledge_amount 100.00
    pledge_frequency 1.0
    pledge_received true
    pledge_start_date '2016-01-01 14:20:20 -0500'
  end
end
