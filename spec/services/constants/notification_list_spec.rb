require 'spec_helper'

RSpec.describe Constants::NotificationList, type: :model do
  subject { Constants::NotificationList.new }

  context '#organizations' do
    it { expect(subject.notifications).to be_a Hash }

    it 'should consist of string/symbol pairs' do
      subject.notifications.each do |id, record|
        expect(id).to be_a Fixnum
        expect(record).to be_a Notification
      end
    end
  end

  context '#id' do
    it { expect(subject.id).to be_blank }
  end
end
