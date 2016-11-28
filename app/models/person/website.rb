class Person::Website < ActiveRecord::Base
	belongs_to :person
  
  PERMITTED_ATTRIBUTES = [
    :primary_url, :url
  ].freeze

  validates :url, :person_id, presence: true

end
