FactoryGirl.define do
  factory :name_male_ratio do
    sequence(:name) { |n| "Name#{n}" }
    male_ratio 0.5
  end
end
