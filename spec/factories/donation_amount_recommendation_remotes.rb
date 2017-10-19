FactoryGirl.define do
  factory :donation_amount_recommendation_remote, class: 'DonationAmountRecommendation::Remote' do
    organization
    donor_number 'MyString'
    designation_number 'MyString'
    previous_amount 9.99
    amount 9.99
    started_at { Time.zone.now - 1.year }
    gift_min 0
    gift_max 100
    income_min 50_000
    income_max 75_000
    suggested_pledge_amount 25
    ask_at { Time.zone.now + 5.days }
    zip_code '32817'
  end
end
