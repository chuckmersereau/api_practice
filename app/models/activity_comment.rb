class ActivityComment < ApplicationRecord
  belongs_to :activity, counter_cache: true, touch: true
  belongs_to :person

  validates :body, presence: true

  PERMITTED_ATTRIBUTES = [:body, :created_at, :overwrite, :person_id, :updated_at, :updated_in_db_at, :uuid].freeze
end
