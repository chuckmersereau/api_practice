class PledgeDonation < ApplicationRecord
  belongs_to :pledge
  belongs_to :donation

  validates :donation_id, uniqueness: { scope: :pledge_id }
  validates :pledge_id, uniqueness: { scope: :donation_id }

  after_save :set_processed, if: :donation_id_changed?
  after_destroy :set_processed

  delegate :set_processed, to: :pledge
end
