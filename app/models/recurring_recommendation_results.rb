class RecurringRecommendationResults < ActiveRecord::Base
  validates :result, presence: true
  validates :contact_id, presence: true
  validates :account_list_id, presence: true
  validates_uniqueness_of :contact_id, :account_list_id
end
