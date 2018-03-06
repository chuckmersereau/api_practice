FactoryGirl.define do
  factory :account_list_invite do
    code 'abc'
    account_list
    association :invited_by_user, factory: :user
    recipient_email 'joe@example.com'
    accepted_at Date.new
  end
end
