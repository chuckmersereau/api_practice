class Pledge < ApplicationRecord
  audited associated_with: :appeal, on: [:destroy]

  belongs_to :account_list
  belongs_to :appeal
  belongs_to :contact
  has_many :pledge_donations, dependent: :destroy
  has_many :donations, through: :pledge_donations

  validates :account_list, :amount, :contact, :expected_date, presence: true
  validates :appeal_id, uniqueness: { scope: :contact_id }

  PERMITTED_ATTRIBUTES = [:amount,
                          :amount_currency,
                          :appeal_id,
                          :created_at,
                          :contact_id,
                          :donation_id,
                          :expected_date,
                          :overwrite,
                          :status,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  enum status: {
    not_received: 'not_received',
    received_not_processed: 'received_not_processed',
    processed: 'processed'
  }

  def merge(loser)
    return unless appeal_id == loser.appeal_id

    loser.pledge_donations.each do |pledge_donation|
      pledge_donation.update!(pledge: self)
    end

    if loser.amount.to_d > amount.to_d
      merged_attributes = [:amount, :amount_currency, :expected_date]
      loser_attrs = loser.attributes.symbolize_keys.slice(*merged_attributes).reject { |_, v| v.blank? }
      update(loser_attrs)
    end

    set_processed

    # must reload first so it doesn't try delete the donations we just moved over
    loser.reload.destroy
  end

  def set_processed
    update(status: pledge_status)
  end

  private

  def pledge_status
    all_donations_have_been_received? ? :processed : :received_not_processed
  end

  def all_donations_have_been_received?
    # floating point comparison us yucky, converting to a BigDecimal should be a little better
    amount.to_d <= donations.reload.to_a.sum(&:converted_amount).to_d
  end
end
