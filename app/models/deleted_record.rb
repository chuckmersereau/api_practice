class DeletedRecord < ApplicationRecord
  TYPES = %w(Contact Activity Donation).freeze
  DELETED_FROM_TYPES = %w(AccountList DesignationAccount).freeze

  belongs_to :deletable, polymorphic: true
  belongs_to :deleted_from, polymorphic: true

  belongs_to :deleted_by, class_name: 'Person', foreign_key: 'deleted_by_id'

  validates :deleted_from_id, :deleted_from_type, :deletable_id, :deletable_type, presence: true
  validates :deletable_type, inclusion: { in: TYPES }
  validates :deleted_from_type, inclusion: { in: DELETED_FROM_TYPES }

  scope :account_list_ids, ->(ids) { where(deleted_from_id: ids) }
  scope :since_date, ->(date) { where('deleted_at >= ?', date) }
  scope :between_dates, ->(date_range) { where(deleted_at: date_range) }
  scope :types, ->(types) { where(deletable_type: types.to_s.gsub('Task', 'Activity').split(',')) }
end
