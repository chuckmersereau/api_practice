FactoryGirl.define do
  factory :donation_amount_recommendation do
    suggested_pledge_amount 25
    suggested_special_amount 50
    ask_at { Time.zone.now + 5.days }
    after(:build) do |record|
      record.build_designation_account(attributes_for(:designation_account)) unless record.designation_account
      record.build_donor_account(attributes_for(:donor_account)) unless record.donor_account
    end
  end
end
