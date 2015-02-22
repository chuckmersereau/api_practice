# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :appeal do
    account_list
    name 'Appeal 1'
    amount 1000.0
    description 'First appeal'
  end
end
