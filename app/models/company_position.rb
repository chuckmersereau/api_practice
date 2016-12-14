class CompanyPosition < ApplicationRecord
  belongs_to :person
  belongs_to :company

  # attr_accessible :position

  def to_s
    position
  end
end
