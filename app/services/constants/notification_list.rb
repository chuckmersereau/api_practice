class Constants::NotificationList
  alias read_attribute_for_serialization send

  def notifications
    @notifications ||= notifications_hash
  end

  def id
  end

  private

  def notifications_hash
    Hash[
      NotificationType.all.map { |nt| [nt.id, nt] }
    ]
  end
end
