class CompanyPosition < ApplicationRecord
  belongs_to :person
  belongs_to :company

  def to_s
    position
  end
end
