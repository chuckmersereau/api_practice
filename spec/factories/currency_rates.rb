# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :currency_rate do
    exchanged_on { Date.current }
    code 'EUR'
    source 'test'
    rate 1.13
  end
end
