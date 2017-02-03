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

  context '#currencies' do
    it { expect(subject.currencies).to be_a_hash_with_types String, String }
  end

  context '#organizations' do
    before { 5.times { create(:organization) } }
    it { expect(subject.organizations).to be_a_hash_with_types Fixnum, String }
  end

  context '#notifications' do
    before { 5.times { create(:notification) } }
    it { expect(subject.notifications).to be_a_hash_with_types Fixnum, String }
  end

  context '#locales' do
    it { expect(subject.locales).to be_a_hash_with_types Symbol, String }

    it 'should have a name with the locale code in parentheses' do
      subject.locales.each do |_code, locale|
        expect(locale).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locales.each do |code, _locale|
        expect(code).to match(/\w\w/)
      end
    end
  end

  context '#pledge_frequencies' do
    it { expect(subject.pledge_frequencies).to be_a_hash_with_types Numeric, String }
  end

  %w(
    assignable_likely_to_give
    assignable_send_newsletter
    statuses
  ).each do |attribute|
    context "##{attribute}" do
      it 'should consist of string/symbol pairs' do
        subject.send(attribute.to_sym).each do |contact|
          expect(contact).to be_a(String)
        end
      end
    end
  end
end