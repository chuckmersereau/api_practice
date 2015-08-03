# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_list_invite do
    account_list
    user
    recipient_email 'joe@example.com'
    code 'abc'
  end
end
