FactoryGirl.define do
  factory :nickname do
    sequence(:name) { |n| "Name#{n}" }
    sequence(:nickname) { |n| "NickName#{n}" }
    num_merges 1
    num_not_duplicates 1
    num_times_offered 1
  end
end
