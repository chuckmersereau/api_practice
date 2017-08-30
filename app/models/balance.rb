class Balance < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  validates :balance, :resource, presence: true
end
