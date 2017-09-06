class PledgeDonation < ApplicationRecord
  belongs_to :pledge
  belongs_to :donation

  validates :donation_id, uniqueness: { scope: :pledge_id }
  validates :pledge_id, uniqueness: { scope: :donation_id }

  after_save :set_processed, if: :donation_id_changed?
  after_destroy :set_processed

  private

  def set_processed
    pledge.update(processed: all_donations_have_been_received?)
  end

  def all_donations_have_been_received?
    pledge.amount <= pledge.donations.reload.to_a.sum(&:converted_amount)
  end
end
