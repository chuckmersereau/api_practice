class NotificationPreferenceSerializer < ApplicationSerializer
  attributes :actions,
             :type

  belongs_to :account_list
  belongs_to :notification_type
end
