require 'spec_helper'

describe Constants::NotificationListSerializer do
  subject { Constants::NotificationListSerializer.new(notification_list) }
  let(:notification_list) { Constants::NotificationList.new }

  before { 5.times { create(:notification) } }

  context '#notifications' do
    it 'should be an array' do
      expect(subject.notifications).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.notifications.each do |notification|
        expect(notification.size).to eq 2
        expect(notification.first).to be_a(String)
        expect(notification.second).to be_a(Fixnum)
      end
    end
  end

  context '#notifications_exhibit' do
    it { expect(subject.notifications_exhibit).to be_a NotificationListExhibit }
  end
end
