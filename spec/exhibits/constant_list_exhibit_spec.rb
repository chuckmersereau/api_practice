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

  context '.applicable_to?' do
    it 'applies only to ConstantList and not other stuff' do
      expect(ConstantListExhibit.applicable_to?(ConstantList.new)).to be true
      expect(ConstantListExhibit.applicable_to?(Address.new)).to be false
    end
  end

  context '#locale_name_map' do
    it 'should have the correct data structure' do
      subject.locale_name_map.each do |_code, locale|
        expect(locale).to be_a_hash_with_types Symbol, String
      end
      expect(subject.locale_name_map).to be_a_hash_with_types Symbol, Hash
    end

    it 'should have a name with the locale code in parentheses' do
      subject.locale_name_map.each do |_code, locale|
        expect(locale[:english_name]).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locale_name_map.each do |code, _locale|
        expect(code).to match(/\w\w/)
      end
    end
  end

  context '#date_formats_map' do
    it { expect(subject.date_formats_map).to be_a_hash_with_types String, String }
  end

  context '#languages_map' do
    it { expect(subject.languages_map).to be_a_hash_with_types String, String }
  end

  context '#pledge_currencies_code_symbol_map' do
    it { expect(subject.pledge_currencies_code_symbol_map).to be_a_hash_with_types String, Hash }
    it { expect(subject.pledge_currencies_code_symbol_map['USD'][:code]).to eq('USD') }
    it { expect(subject.pledge_currencies_code_symbol_map['USD'][:code_symbol_string]).to eq('USD ($)') }
    it { expect(subject.pledge_currencies_code_symbol_map['USD'][:name]).to eq('US dollar') }
    it { expect(subject.pledge_currencies_code_symbol_map['USD'][:symbol]).to eq('$') }
  end

  context '#currency_code_and_symbol' do
    it 'renders the code in parentheses' do
      expect(subject.currency_code_and_symbol('CAD')).to eq 'CAD ($)'
      expect(subject.currency_code_and_symbol('CNY')).to eq 'CNY (¥)'
    end
  end

  context '#locale_display_name' do
    it 'renders the code in parentheses' do
      expect(subject.locale_display_name('Urdu', 'ur')).to eq 'Urdu (ur)'
      expect(subject.locale_display_name('Thai', :th)).to eq 'Thai (th)'
    end
  end

  context '#bulk_update_options' do
    let(:opts) { subject.bulk_update_options }

    it { expect(opts['likely_to_give']).to eq subject.assignable_likely_to_give }
    it { expect(opts['status']).to eq subject.assignable_statuses }
    it { expect(opts['send_newsletter']).to eq subject.assignable_send_newsletter }
  end

  context '#activity_translated_hashes' do
    it 'should return array of hashes' do
      subject.activity_translated_hashes.each do |activity|
        expect(activity).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :activity_translated_hashes
  end

  context '#assignable_likely_to_give_translated_hashes' do
    it 'should return array of hashes' do
      subject.assignable_likely_to_give_translated_hashes.each do |likelihood|
        expect(likelihood).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_likely_to_give_translated_hashes
  end

  context '#assignable_send_newsletter_translated_hashes' do
    it 'should return array of hashes' do
      subject.assignable_send_newsletter_translated_hashes.each do |newsletter|
        expect(newsletter).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_send_newsletter_translated_hashes
  end

  context '#status_translated_hashes' do
    it 'should return array of hashes' do
      subject.status_translated_hashes.each do |status|
        expect(status).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :status_translated_hashes
  end

  context '#pledge_frequency_translated_hashes' do
    it 'should return array of hashes' do
      subject.pledge_frequency_translated_hashes.each do |pledge_frequency|
        expect(pledge_frequency).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :pledge_frequency_translated_hashes
  end

  context '#assignable_location_translated_hashes' do
    it 'should return array of hashes' do
      subject.assignable_location_translated_hashes.each do |assignable_location|
        expect(assignable_location).to be_a Hash
      end
    end

    include_examples 'expect method to translate values', method: :assignable_location_translated_hashes
  end

  context '#notification_translated_hashes' do
    before do
      NotificationTypesSeeder.new(true).seed
    end

    it 'should return array of hashes' do
      subject.notification_translated_hashes.each do |notification|
        expect(notification).to be_a Hash
      end
    end

    it 'should translate' do
      expect(FastGettext).to receive('cached_find').at_least(:once)
      subject.notification_translated_hashes
    end
  end

  context '#pledge_frequencies_translated_hashes' do
    it 'should return array of hashes' do
      subject.pledge_frequencies_translated_hashes.each do |frequency|
        expect(frequency).to be_a Hash
        expect(frequency.keys).to eq([:id, :value])
      end
    end

    include_examples 'expect method to translate values', method: :pledge_frequencies_translated_hashes
  end

  context '#send_appeals_translated_hashes' do
    it 'should return array of hashes' do
      subject.send_appeals_translated_hashes.each do |send_appeal|
        expect(send_appeal).to be_a Hash
        expect(send_appeal.keys).to eq([:id, :value])
      end
    end

    include_examples 'expect method to translate values', method: :send_appeals_translated_hashes
  end
end
