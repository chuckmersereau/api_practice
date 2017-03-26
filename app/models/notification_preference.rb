class NotificationPreference < ApplicationRecord
  belongs_to :account_list
  belongs_to :notification_type

  serialize :actions, Array

  before_save :normalize_actions

  validates :notification_type_id, presence: true

  delegate :type, to: :notification_type

  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    {
      actions: []
    },
    :created_at,
    :id,
    :notification_type_id,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  def self.default_actions
    %w(email task)
  end

  private

  def normalize_actions
    self.actions = Array[actions].tap do |array|
      array.flatten!
      array.uniq!
      array.select!(&:present?)
      array.sort!
    end
  end
end
