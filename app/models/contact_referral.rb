class ContactReferral < ApplicationRecord
  PERMITTED_ATTRIBUTES = [:created_at,
                          :overwrite,
                          :referred_by_id,
                          :referred_to_id,
                          :updated_at,
                          :updated_in_db_at,
                          :id].freeze

  belongs_to :referred_by, class_name: 'Contact', foreign_key: :referred_by_id
  belongs_to :referred_to, class_name: 'Contact', foreign_key: :referred_to_id

  validates :referred_by_id, presence: true
  validates :referred_to_id, presence: true
end
