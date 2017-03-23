require 'rails_helper'

RSpec.describe ConstantList, type: :model do
  subject { ConstantList.new }

  describe '#currencies' do
    it { expect(subject.codes).to be_a Array }

    it 'should consist of ISO 4217 currency codes' do
      subject.codes.each do |currency|
        expect(currency).to match(/\A\w{3}\z/)
      end
    end
  end

  describe '#locales' do
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

  describe '#notifications' do
    before { create :notification_type }

    it { expect(subject.notifications).to be_a_hash_with_types String, String }
  end

  describe '#organizations' do
    before { 5.times { create(:organization) } }
    it { expect(subject.organizations).to be_a_hash_with_types String, String }
  end

  describe '#assignable_locations' do
    it { expect(subject.assignable_locations).to be_an Array }
    it { subject.assignable_locations.each { |loc| expect(loc).to be_a String } }
  end

  describe '#csv_import' do
    it { expect(subject.csv_import).to be_an Hash }
    it { expect(subject.csv_import[:supported_headers]).to be_an Hash }
    it { expect(subject.csv_import[:required_headers]).to be_an Hash }
    it { expect(subject.csv_import[:constants]).to be_an Hash }
    it { expect(subject.csv_import[:constants].keys & subject.csv_import[:supported_headers].keys).to eq subject.csv_import[:constants].keys }
  end

  context '#sources' do
    it { expect(subject.sources).to be_a_hash_with_types Symbol, Array }
  end
end
