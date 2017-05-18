class Notification < ApplicationRecord
  belongs_to :contact, inverse_of: :notifications
  belongs_to :notification_type
  belongs_to :donation
  has_one :account_list, through: :contact
  has_many :tasks, inverse_of: :notification, dependent: :destroy

  scope :active, -> { where(cleared: false) }

  validates :event_date, presence: true

  PERMITTED_ATTRIBUTES = [:cleared,
                          :contact_id,
                          :created_at,
                          :donation_id,
                          :event_date,
                          :notification_type_id,
                          :overwrite,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze
end
