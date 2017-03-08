require 'rails_helper'

describe ConstantListExhibit do
  subject { ConstantListExhibit.new(constant_list, context) }
  let(:context) { double }
  let(:constant_list) { ConstantList.new }

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

  context '#activities_translated' do
    it do
      subject.activities_translated.each do |activity|
        expect(activity).to be_a String
      end
    end
  end

  context '#assignable_likely_to_give_translated' do
    it do
      subject.assignable_likely_to_give_translated.each do |likelihood|
        expect(likelihood).to be_a String
      end
    end
  end

  context '#assignable_send_newsletter_translated' do
    it do
      subject.assignable_send_newsletter_translated.each do |newsletter|
        expect(newsletter).to be_a String
      end
    end
  end

  context '#statuses_translated' do
    it do
      subject.statuses_translated.each do |status|
        expect(status).to be_a String
      end
    end
  end

  context '#notifications_translated' do
    it do
      subject.notifications_translated.each do |_, status|
        expect(status).to be_a String
      end
    end
  end
end
