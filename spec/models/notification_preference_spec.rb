require 'rails_helper'

describe NotificationPreference do
  describe 'action normalization' do
    let(:notification_preference) { create(:notification_preference) }

    it 'should turn nil into an empty array' do
      notification_preference.actions = nil

      notification_preference.save

      expect(notification_preference.actions).to eq([])
    end

    it 'should turn "" into an empty array' do
      notification_preference.actions = ''

      notification_preference.save

      expect(notification_preference.actions).to eq([])
    end

    it 'should reject blank elements in an array' do
      notification_preference.actions = ['foo', '', nil]

      notification_preference.save

      expect(notification_preference.actions).to eq(['foo'])
    end

    it 'should remove duplicate elements from the array' do
      notification_preference.actions = %w(foo foo)

      notification_preference.save

      expect(notification_preference.actions).to eq(['foo'])
    end

    it 'should flatten nested arrays' do
      notification_preference.actions = [['foo']]

      notification_preference.save

      expect(notification_preference.actions).to eq(['foo'])
    end

    it 'should sort the array' do
      notification_preference.actions = %w(foo bar)

      notification_preference.save

      expect(notification_preference.actions).to eq(%w(bar foo))
    end
  end
end
