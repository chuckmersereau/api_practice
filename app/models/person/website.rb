class Person::Website < ApplicationRecord
  belongs_to :person

  PERMITTED_ATTRIBUTES = [
    :primary_url, :url
  ].freeze

  validates :url, presence: true
end
