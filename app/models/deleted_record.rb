class DeletedRecord < ApplicationRecord
  TYPES = %w(Contact Activity).freeze

  belongs_to :deletable, polymorphic: true
  belongs_to :account_list
  belongs_to :deleted_by, class_name: 'Person', foreign_key: 'deleted_by_id'

  validates :account_list_id, :deletable_id, :deletable_type, presence: true
  validates :deletable_type, inclusion: { in: TYPES }

  scope :account_list_ids, ->(ids) { where(account_list_id: ids) }
  scope :since_date, ->(date) { where('deleted_at >= ?', date) }
  scope :between_dates, ->(date_range) { where(deleted_at: date_range) }
  scope :types, ->(types) { where(deletable_type: types.to_s.gsub('Task', 'Activity').split(',')) }
end
