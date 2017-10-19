class DonationAmountRecommendationSerializer < ApplicationSerializer
  belongs_to :designation_account
  belongs_to :donor_account

  attributes :ask_at,
             :started_at,
             :suggested_pledge_amount,
             :suggested_special_amount
end
