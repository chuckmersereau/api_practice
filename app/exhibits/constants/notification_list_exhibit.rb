class NotificationListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'Constants::NotificationList'
  end
end
