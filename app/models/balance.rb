class Balance < ApplicationRecord
  belongs_to :resource, polymorphic: true
  validates :balance, :resource, presence: true
end
