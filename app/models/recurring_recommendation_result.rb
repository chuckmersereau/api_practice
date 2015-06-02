class RecurringRecommendationResult < ActiveRecord::Base
  validates :result, presence: true
  validates :contact_id, presence: true
  validates :account_list_id, presence: true
end
