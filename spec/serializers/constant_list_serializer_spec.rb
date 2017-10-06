require 'rails_helper'

describe ConstantListSerializer do
  let(:serializer) { ConstantListSerializer.new(constant_list) }
  subject { serializer }
  let(:constant_list) { ConstantList.new }

  context '#activities' do
    it { expect(subject.activities).to be_an Array }

    it 'all elements should be strings' do
      subject.activities.each do |activity|
        expect(activity).to be_a(String)
      end
    end
  end

  context '#organizations' do
    before { 5.times { create(:organization) } }
    it { expect(subject.organizations).to be_a_hash_with_types String, String }
  end

  context '#organizations_attributes' do
    before { 5.times { create(:organization) } }
    it { expect(subject.organizations_attributes).to be_a_hash_with_types String, Hash }
  end

  context '#notifications' do
    before { 5.times { create(:notification) } }
    it { expect(subject.notifications).to be_a_hash_with_types String, String }
  end

  context '#locales' do
    it 'should have the correct data structure' do
      subject.locales.each do |_code, locale|
        expect(locale).to be_a_hash_with_types Symbol, String
      end
      expect(subject.locales).to be_a_hash_with_types Symbol, Hash
    end

    it 'should have an english name with the locale code in parentheses' do
      subject.locales.each do |_code, locale|
        expect(locale[:english_name]).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
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

    it 'ideally would underscore keys but it should not underscore the frequencies to support clients that are still depending on it' do
      subject.pledge_frequencies.keys.each do |key|
        expect(key).to be_a(BigDecimal)
        expect(key.to_s).to include('.')
        expect(key.to_s).to_not include('_')
      end
    end
  end

  context '#send_appeals_hashes' do
    it { expect(subject.send_appeals_hashes).to be_a(Array) }
    it { subject.send_appeals_hashes.each { |hash| expect(hash).to be_a(Hash) } }
  end

  context '#dates' do
    it { expect(subject.dates).to be_a_hash_with_types String, String }
  end

  context '#languages' do
    it { expect(subject.languages).to be_a_hash_with_types String, String }
  end

  context '#activity_hashes' do
    it { expect(subject.activity_hashes.first).to be_a_hash_with_types Symbol, String }
  end

  context '#assignable_location_hashes' do
    it { expect(subject.assignable_location_hashes.first).to be_a_hash_with_types Symbol, String }
  end

  context '#assignable_likely_to_give_hashes' do
    it { expect(subject.assignable_likely_to_give_hashes.first).to be_a_hash_with_types Symbol, String }
  end

  context '#assignable_send_newsletter_hashes' do
    it { expect(subject.assignable_send_newsletter_hashes.first).to be_a_hash_with_types Symbol, String }
  end

  context '#status_hashes' do
    it { expect(subject.status_hashes.first).to be_a_hash_with_types Symbol, String }
  end

  context '#pledge_frequency_hashes' do
    let(:first_pledge_frequency_hash) { subject.pledge_frequency_hashes.first }

    it do
      expect(first_pledge_frequency_hash[:id]).to be_a String
      expect(first_pledge_frequency_hash[:key]).to be_a BigDecimal
    end
  end

  context '#notification_translated_hashes' do
    let!(:notification_type) { create(:notification_type) }

    it { expect(subject.notification_translated_hashes.first).to be_a_hash_with_types Symbol, String }
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
