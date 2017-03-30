class PledgeDonation < ApplicationRecord
  belongs_to :pledge
  belongs_to :donation

  validates :donation_id, uniqueness: { scope: :pledge_id }
  validates :pledge_id, uniqueness: { scope: :donation_id }
end
