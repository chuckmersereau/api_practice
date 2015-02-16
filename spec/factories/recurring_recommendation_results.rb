# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recurring_recommendation_results do
    contact_id '1234561'
    account_list_id '789012'
    result 'test result message'
  end
end
