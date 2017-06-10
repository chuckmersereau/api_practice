class NotificationPreference < ApplicationRecord
  belongs_to :account_list
  belongs_to :notification_type

  serialize :actions, Array

  validates :notification_type_id, presence: true

  delegate :type, to: :notification_type

  PERMITTED_ATTRIBUTES = [
    {
      actions: []
    },
    :actions,
    :created_at,
    :id,
    :notification_type_id,
    :overwrite,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  def self.default_actions
    %w(email task)
  end

  def actions=(actions)
    actions = actions.split(',').map(&:strip) if actions.is_a?(String)

    value = Array[actions].tap do |array|
      array.flatten!
      array.uniq!
      array.select!(&:present?)
      array.sort!
    end
    self[:actions] = value
  end
end
