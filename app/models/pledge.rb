class Pledge < ApplicationRecord
  belongs_to :account_list
  belongs_to :contact
  belongs_to :donation

  validates :contact_id, :account_list_id, :amount, :expected_date, presence: true

  PERMITTED_ATTRIBUTES = [:amount,
                          :created_at,
                          :contact_id,
                          :donation_id,
                          :expected_date,
                          :overwrite,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze
end
