class NotificationMailerPreview < ApplicationPreview
  def notify
    type = NotificationType::SpecialGift.first
    contact = Contact.first || Contact.new(name: 'Bright, Bill')
    contact.name = '<h3>asdf</h3>'
    donation = Donation.new(amount: '20', donation_date: Date.yesterday)
    notification = Notification.new(notification_type: type, contact: contact,
                                    event_date: DateTime.now, donation: donation)
    NotificationMailer.notify(user, type => [notification])
  end
end
