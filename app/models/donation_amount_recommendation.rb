# This model contains donation amount (recurring & one-off) recommendations for
# a donor_account in relation to a designation_account
class DonationAmountRecommendation < ApplicationRecord
  belongs_to :donor_account, inverse_of: :donation_amount_recommendations
  belongs_to :designation_account, inverse_of: :donation_amount_recommendations
  validates :donor_account, :designation_account, presence: true
end
