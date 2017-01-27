require 'spec_helper'

RSpec.describe ConstantList, type: :model do
  subject { ConstantList.new }

  context '#currencies' do
    it { expect(subject.codes).to be_a Array }

    it 'should consist of ISO 4217 currency codes' do
      subject.codes.each do |currency|
        expect(currency).to match(/\A\w{3}\z/)
      end
    end
  end

  context '#locales' do
    it { expect(subject.locales).to be_an Array }

    it 'should consist of string/symbol pairs' do
      subject.locales.each do |locale|
        expect(locale.size).to eq 2
        expect(locale.first).to be_a(String)
        expect(locale.second).to be_a(Symbol)
      end
    end

    it 'should contain a locale code' do
      subject.locales.each do |locale|
        expect(locale.second).to match(/\A\w+(?:-\w+)?\z/)
      end
    end
  end

  context '#organizations' do
    it { expect(subject.notifications).to be_a Hash }

    it 'should consist of string/symbol pairs' do
      subject.notifications.each do |id, record|
        expect(id).to be_a Fixnum
        expect(record).to be_a Notification
      end
    end
  end

  context '#organizations' do
    before { 5.times { create(:organization) } }

    it { expect(subject.organizations).to be_a Hash }

    it 'should consist of string/symbol pairs' do
      subject.organizations.each do |id, record|
        expect(id).to be_a Fixnum
        expect(record).to be_a Organization
      end
    end
  end
end
