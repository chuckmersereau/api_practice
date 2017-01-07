require 'spec_helper'

describe NotificationListExhibit do
  let(:context) { double }
  let(:exhibit) { NotificationListExhibit.new(notification_list, context) }
  let(:notification_list) { Constants::NotificationList.new }

  context '.applicable_to?' do
    it 'applies only to NotificationList and not other stuff' do
      expect(NotificationListExhibit.applicable_to?(Constants::NotificationList.new)).to be true
      expect(NotificationListExhibit.applicable_to?(Address.new)).to be false
    end
  end
end
