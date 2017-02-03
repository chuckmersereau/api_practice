class User::Option < ApplicationRecord
  PERMITTED_ATTRIBUTES = [:created_at,
                          :key,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid,
                          :value].freeze

  belongs_to :user
  validates :user, :key, presence: true
  validates :key,
            uniqueness: { scope: :user_id },
            format: { with: /\A[A-Za-z0-9_]*\z/ }
end