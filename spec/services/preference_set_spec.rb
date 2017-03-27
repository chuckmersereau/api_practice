require 'rails_helper'
require Rails.root.join('db', 'seeders', 'notification_types_seeder.rb')

describe PreferenceSet, type: :model do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe '#notification_settings=' do
    before do
      NotificationTypesSeeder.new.seed # Specs depend on NotificationType records.
      NotificationType.all.each_with_index do |type, index|
        actions = index.even? ? %w(task) : %w(task email)
        account_list.notification_preferences.new(notification_type_id: type.id, actions: actions)
      end
    end

    it 'clears all notifications if set to "none"' do
      PreferenceSet.new(user: user, account_list: account_list, notification_settings: 'none')

      notification_settings = account_list.notification_preferences.to_a
      expect(notification_settings.count).to_not be 0
      notification_settings = notification_settings.select do |ns|
        ns.actions.any?
      end
      expect(notification_settings.count).to be 0
    end

    it 'sets all notifications to defaults if set to "default"' do
      PreferenceSet.new(user: user, account_list: account_list, notification_settings: 'default')

      notification_settings = account_list.notification_preferences.to_a
      expect(notification_settings.count).to_not be 0
      notification_settings = notification_settings.reject do |ns|
        ns.actions == NotificationPreference.default_actions
      end
      non_default_types = notification_settings.collect(&:notification_type).collect(&:type)
      expect(non_default_types).to include 'NotificationType::CallPartnerOncePerYear'
      expect(non_default_types).to include 'NotificationType::ThankPartnerOncePerYear'
    end
  end
end
