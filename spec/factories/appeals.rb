# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :appeal do
    name 'Appeal 1'
    account_list
    amount 1000.0
    description 'First appeal'
  end
end
