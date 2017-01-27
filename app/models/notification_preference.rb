class NotificationPreference < ApplicationRecord
  belongs_to :account_list
  belongs_to :notification_type

  serialize :actions
  # attr_accessible :actions, :notification_type_id
  validates :actions, :notification_type_id, presence: true

  delegate :type, to: :notification_type

  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :actions,
                          :created_at,
                          :notification_type_id,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def self.default_actions
    %w(email task)
  end
end
