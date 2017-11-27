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

    it 'should not include currencies no longer in use (eg. AFA and ADP)' do
      subject.codes.each do |currency|
        expect(currency).not_to include('ADP', 'AFA')
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

  describe '#organizations_attributes' do
    before { 5.times { create(:organization) } }
    it { expect(subject.organizations_attributes).to be_a_hash_with_types String, Hash }
    it 'keys matches array' do
      expect(subject.organizations_attributes.first[1].keys).to match_array %i(name api_class help_email oauth)
    end
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
    it { expect(subject.csv_import[:constants].keys).to eq CsvImport.constants.keys }
    it { expect(subject.csv_import[:max_file_size_in_bytes]).to eq Import::MAX_FILE_SIZE_IN_BYTES }
  end

  describe '#tnt_import' do
    it { expect(subject.tnt_import[:max_file_size_in_bytes]).to eq Import::MAX_FILE_SIZE_IN_BYTES }
  end

  context '#sources' do
    it { expect(subject.sources).to be_a_hash_with_types Symbol, Array }
  end

  context '#send_appeals' do
    it { expect(subject.send_appeals).to be_a Hash }
  end
end
