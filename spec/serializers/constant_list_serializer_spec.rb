require 'spec_helper'

describe ConstantListSerializer do
  subject { ConstantListSerializer.new(constant_list) }
  let(:constant_list) { ConstantList.new }

  context '#activities' do
    it { expect(subject.activities).to be_an Array }

    it 'all elements should be strings' do
      subject.activities.each do |activity|
        expect(activity).to be_a(String)
      end
    end
  end

  context '#currencys' do
    it { expect(subject.currencies).to be_an Array }

    it 'should consist of string/symbol pairs' do
      subject.currencies.each do |currency|
        expect(currency.size).to eq 2
        expect(currency.first).to be_a(String)
        expect(currency.second).to be_a(String)
      end
    end
  end

  context '#organizations' do
    before { 5.times { create(:organization) } }

    it 'should be an array' do
      expect(subject.organizations).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.organizations.each do |organization|
        expect(organization.size).to eq 2
        expect(organization.first).to be_a(String)
        expect(organization.second).to be_a(Fixnum)
      end
    end
  end

  context '#notifications' do
    before { 5.times { create(:notification) } }

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

  context '#locales' do
    it 'should be an array' do
      expect(subject.locales).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.locales.each do |locale|
        expect(locale.size).to eq 2
        expect(locale.first).to be_a(String)
        expect(locale.second).to be_a(Symbol)
      end
    end

    it 'should have a name with the locale code in parentheses' do
      subject.locales.each do |locale|
        expect(locale.first).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locales.each do |locale|
        expect(locale.second).to match(/\w\w/)
      end
    end
  end

  %w(
    assignable_likely_to_give
    assignable_send_newsletter
    pledge_currencies
    statuses
  ).each do |attribute|
    context "##{attribute}" do
      it 'should consist of string/symbol pairs' do
        subject.send(attribute.to_sym).each do |contact|
          expect(contact.size).to eq 2
          expect(contact.first).to be_a(String)
          expect(contact.second).to be_a(String)
        end
      end
    end
  end

  context '#pledge_frequencies' do
    it 'should consist of string/number pairs' do
      subject.pledge_frequencies.each do |contact|
        expect(contact.size).to eq 2
        expect(contact.first).to be_a(String)
        expect(contact.second).to be_a(Numeric)
      end
    end
  end
end
