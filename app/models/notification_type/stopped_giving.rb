class NotificationType::StoppedGiving < NotificationType
  def check(account_list)
    notifications = []
    account_list.contacts.financial_partners.where(['pledge_start_date is NULL OR pledge_start_date < ?', 30.days.ago]).find_each do |contact|
      next unless contact.pledge_received?

      late = contact.late_by?(30.days)

      prior_notification = Notification.active.find_by(contact_id: contact.id, notification_type_id: id)

      if late
        unless prior_notification
          # If they've never given, they haven't missed a gift
          if contact.donations.first
            notification = contact.notifications.create!(notification_type_id: id, event_date: Date.today)
            notifications << notification
          end
        end
      elsif prior_notification
        # Clear a prior notification if there was one
        prior_notification.update_attributes(cleared: true)
        # Remove any tasks associated with this notification
        prior_notification.tasks.destroy_all
      end
    end
    notifications
  end

  def task_description_template(_notification = nil)
    _('%{contact_name} seems to have missed a gift. Call to follow up.')
  end

  protected

  def task_activity_type
    _('Call')
  end
end
