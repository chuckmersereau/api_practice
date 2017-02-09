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
    it { expect(subject.locale_name_map).to be_a_hash_with_types Symbol, String }

    it 'should have a name with the locale code in parentheses' do
      subject.locale_name_map.each do |_code, locale|
        expect(locale).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locale_name_map.each do |_code, locale|
        expect(locale).to match(/\w\w/)
      end
    end
  end

  context '#pledge_currencies_code_symbol_map' do
    it { expect(subject.pledge_currencies_code_symbol_map).to be_a_hash_with_types String, String }
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
end
