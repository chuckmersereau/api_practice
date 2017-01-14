class Contact
  class AnalyticsSerializer < ::ServiceSerializer
    attributes :first_gift_not_received_count,
               :partners_30_days_late_count,
               :partners_60_days_late_count

    has_many :birthdays_this_week
    has_many :anniversaries_this_week
  end
end
