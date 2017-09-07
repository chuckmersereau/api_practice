class Pledge < ApplicationRecord
  belongs_to :account_list
  belongs_to :appeal
  belongs_to :contact
  has_many :pledge_donations, dependent: :destroy
  has_many :donations, through: :pledge_donations

  validates :contact_id, :account_list_id, :amount, :amount_currency, :expected_date, presence: true

  PERMITTED_ATTRIBUTES = [:amount,
                          :amount_currency,
                          :appeal_id,
                          :created_at,
                          :contact_id,
                          :donation_id,
                          :expected_date,
                          :overwrite,
                          :received_not_processed,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze
end
