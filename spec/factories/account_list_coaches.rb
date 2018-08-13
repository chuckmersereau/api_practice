FactoryBot.define do
  factory :account_list_coach do
    association :coach, factory: :user_coach
    account_list
  end
end
