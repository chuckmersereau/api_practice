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
  end

  context '#dates' do
    it { expect(subject.dates).to be_a_hash_with_types String, String }
  end

  context '#languages' do
    it { expect(subject.languages).to be_a_hash_with_types String, String }
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

  context '#as_json' do
    subject { serializer.as_json }

    it { should include :activities }
    it { should include :assignable_likely_to_give }
    it { should include :assignable_locations }
    it { should include :assignable_send_newsletter }
    it { should include :assignable_statuses }
    it { should include :dates }
    it { should include :bulk_update_options }
    it { should include :languages }
    it { should include :locales }
    it { should include :next_actions }
    it { should include :notifications }
    it { should include :organizations }
    it { should include :pledge_currencies }
    it { should include :pledge_frequencies }
    it { should include :results }
    it { should include :statuses }
    it { should include :csv_import }
  end
end
