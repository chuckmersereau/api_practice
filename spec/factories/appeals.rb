FactoryGirl.define do
  factory :appeal do
    account_list
    amount 1000.0
    description 'The description for my new Appeal'
    end_date { 1.week.from_now.to_date }

    sequence(:name) { |num| "Appeal ##{num}" }
  end
end
