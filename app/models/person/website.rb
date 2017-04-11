class Person::Website < ApplicationRecord
  belongs_to :person

  PERMITTED_ATTRIBUTES = [:created_at,
                          :overwrite,
                          :primary_url,
                          :updated_at,
                          :updated_in_db_at,
                          :url,
                          :uuid].freeze

  validates :url, presence: true
end
