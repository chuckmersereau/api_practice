FactoryGirl.define do
  factory :currency_alias do
    sequence(:alias_code) { |n| (65 + n).chr }
    sequence(:rate_api_code) { |n| (65 + n).chr }
    ratio 1
  end
end
