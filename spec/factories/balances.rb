FactoryBot.define do
  factory :balance do
    balance { rand(0.0...100.0) }
    association :resource, factory: :designation_account
  end
end
