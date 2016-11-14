# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_list do
    name 'Account List name'
    created_at Date.new
    updated_at Date.new
  end
end
