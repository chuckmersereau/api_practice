class Pledge < ApplicationRecord
  belongs_to :account_list
  belongs_to :appeal
  belongs_to :contact
  has_many :pledge_donations, dependent: :destroy
  has_many :donations, through: :pledge_donations

  validates :account_list, :amount, :contact, :expected_date, presence: true

  PERMITTED_ATTRIBUTES = [:amount,
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
end
