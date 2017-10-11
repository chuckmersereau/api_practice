FactoryGirl.define do
  factory :donation_amount_recommendation do
    organization
    previous_amount 0
    amount 30
    started_at { Time.zone.now - 1.year }
    gift_min 0
    gift_max 100
    income_min 50_000
    income_max 75_000
    suggested_pledge_amount 25
    suggested_special_amount 50
    ask_at { Time.zone.now + 5.days }
    zip_code '32817'
    after(:build) do |record|
      record.build_donor_account(attributes_for(:donor_account))
      record.build_designation_account(attributes_for(:designation_account))
    end
  end
end
