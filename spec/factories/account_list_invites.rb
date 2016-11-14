# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_list_invite do
    code 'abc'
    account_list
    association :invited_by_user, factory: :user
    recipient_email 'joe@example.com'
    invited_by_user_id 1
    accepted_by_user_id 2
    accepted_at Date.new
    cancelled_by_user_id 0
  end
end
