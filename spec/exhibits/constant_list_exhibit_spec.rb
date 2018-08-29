require 'rails_helper'
require Rails.root.join('app', 'seeders', 'notification_types_seeder.rb')

describe ConstantListExhibit do
  subject { ConstantListExhibit.new(constant_list, context) }
  let(:context) { double }
  let(:constant_list) { ConstantList.new }

  shared_examples 'expect method to translate values' do |options|
    before { I18n.locale = :en }
    after { I18n.locale = :en }

    it do
      expect { I18n.locale = :de }.to change { subject.send(options[:method]).first[:value] }
    end
  end

  describe '.applicable_to?' do
    it 'applies only to ConstantList and not other stuff' do
      expect(ConstantListExhibit.applicable_to?(ConstantList.new)).to be true
      expect(ConstantListExhibit.applicable_to?(Address.new)).to be false
    end
  end

  describe '#bulk_update_options' do
    let(:opts) { subject.bulk_update_options }

    it { expect(opts['likely_to_give']).to eq subject.assignable_likely_to_give }
    it { expect(opts['status']).to eq subject.assignable_statuses }
    it { expect(opts['send_newsletter']).to eq subject.assignable_send_newsletter }
  end

  describe '#dates' do
    it { expect(subject.dates).to be_a_hash_with_types String, String }
  end

  describe '#languages' do
    it { expect(subject.languages).to be_a_hash_with_types String, String }
  end

  describe '#locales' do
    it 'should have the correct data structure' do
      subject.locales.each do |_code, locale|
        expect(locale).to be_a_hash_with_types Symbol, String
      end
      expect(subject.locales).to be_a_hash_with_types Symbol, Hash
    end

    it 'should have a name with the locale code in parentheses' do
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

  describe '#pledge_currencies' do
    it { expect(subject.pledge_currencies).to be_a_hash_with_types String, Hash }
    it { expect(subject.pledge_currencies['USD'][:code]).to eq('USD') }
    it { expect(subject.pledge_currencies['USD'][:code_symbol_string]).to eq('USD ($)') }
    it { expect(subject.pledge_currencies['USD'][:name]).to eq('US dollar') }
    it { expect(subject.pledge_currencies['USD'][:symbol]).to eq('$') }
  end

  describe '#pledge_received' do
    it { expect(subject.pledge_received).to eq %w(Yes No) }
  end

  describe '#activity_hashes' do
    it 'should return array of hashes' do
      subject.activity_hashes.each do |activity|
        expect(activity).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :activity_hashes
  end

  describe '#assignable_likely_to_give_hashes' do
    it 'should return array of hashes' do
      subject.assignable_likely_to_give_hashes.each do |likelihood|
        expect(likelihood).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_likely_to_give_hashes
  end

  describe '#assignable_location_hashes' do
    it 'should return array of hashes' do
      subject.assignable_location_hashes.each do |assignable_location|
        expect(assignable_location).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_location_hashes
  end

  describe '#assignable_send_newsletter_hashes' do
    it 'should return array of hashes' do
      subject.assignable_send_newsletter_hashes.each do |newsletter|
        expect(newsletter).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_send_newsletter_hashes
  end

  describe '#assignable_status_hashes' do
    it 'should return array of hashes' do
      subject.assignable_status_hashes.each do |status|
        expect(status).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_status_hashes
  end

  describe '#notification_hashes' do
    before do
      NotificationTypesSeeder.new(true).seed
    end

    it 'should return array of hashes' do
      subject.notification_hashes.each do |notification|
        expect(notification).to be_a Hash
      end
    end

    it 'should translate' do
      expect(FastGettext).to receive('cached_find').at_least(:once)
      subject.notification_hashes
    end
  end

  describe '#pledge_currency_hashes' do
    let(:us_currency) { subject.pledge_currency_hashes.find { |currency| currency[:id] == 'USD' } }

    it { expect(subject.pledge_currency_hashes).to be_a(Array) }
    it { expect(us_currency.keys).to eq(%i(id key value)) }
    it { expect(us_currency[:value]).to eq('USD ($)') }
    it { expect(us_currency[:id]).to eq('USD') }
    it { expect(us_currency[:key]).to eq('USD') }
  end

  describe '#pledge_frequency_hashes' do
    it 'should return array of hashes' do
      subject.pledge_frequency_hashes.each do |pledge_frequency|
        expect(pledge_frequency).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :pledge_frequency_hashes
  end

  describe '#pledge_received_hashes' do
    it 'should return array of hashes' do
      subject.pledge_received_hashes.each do |pledge_received|
        expect(pledge_received).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :pledge_received_hashes
  end

  describe '#send_appeals_hashes' do
    it 'should return array of hashes' do
      subject.send_appeals_hashes.each do |send_appeal|
        expect(send_appeal).to be_a Hash
        expect(send_appeal.keys).to eq([:id, :value])
      end
    end

    include_examples 'expect method to translate values', method: :send_appeals_hashes
  end

  describe '#status_hashes' do
    it 'should return array of hashes' do
      subject.status_hashes.each do |status|
        expect(status).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :status_hashes
  end
end
