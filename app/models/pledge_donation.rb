class PledgeDonation < ApplicationRecord
  belongs_to :pledge
  belongs_to :donation

  validates :donation_id, uniqueness: { scope: :pledge_id }
  validates :pledge_id, uniqueness: { scope: :donation_id }

  after_save :set_processed, if: :donation_id_changed?
  after_destroy :set_processed

  private

  def set_processed
    pledge.update(status: pledge_status)
  end

  def pledge_status
    all_donations_have_been_received? ? :processed : :received_not_processed
  end

  def all_donations_have_been_received?
    # floating point comparison us yucky, converting to a BigDecimal should be a little better
    pledge.amount.to_d <= pledge.donations.reload.to_a.sum(&:converted_amount).to_d
  end
end
