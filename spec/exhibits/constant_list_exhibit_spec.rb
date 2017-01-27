require 'spec_helper'

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

  context '#currency_code_symbol_pairs' do
    it { expect(subject.currency_code_symbol_pairs).to be_an Array }

    it 'should consist of string/symbol pairs' do
      subject.currency_code_symbol_pairs.each do |currency|
        expect(currency.size).to eq 2
        expect(currency.first).to be_a(String)
        expect(currency.second).to be_a(String)
      end
    end
  end

  context '#locale_name_pairs' do
    it 'should be an array' do
      expect(subject.locale_name_pairs).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.locale_name_pairs.each do |locale|
        expect(locale.size).to eq 2
        expect(locale.first).to be_a(String)
        expect(locale.second).to be_a(Symbol)
      end
    end

    it 'should have a name with the locale code in parentheses' do
      subject.locale_name_pairs.each do |locale|
        expect(locale.first).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locale_name_pairs.each do |locale|
        expect(locale.second).to match(/\w\w/)
      end
    end
  end

  context '#notification_description_pairs' do
    before { 5.times { create(:notification) } }

    it 'should be an array' do
      expect(subject.notification_description_pairs).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.notification_description_pairs.each do |notification|
        expect(notification.size).to eq 2
        expect(notification.first).to be_a(String)
        expect(notification.second).to be_a(Fixnum)
      end
    end
  end

  context '#organization_name_pairs' do
    before { 5.times { create(:organization) } }

    it 'should be an array' do
      expect(subject.organization_name_pairs).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.organization_name_pairs.each do |organization|
        expect(organization.size).to eq 2
        expect(organization.first).to be_a(String)
        expect(organization.second).to be_a(Fixnum)
      end
    end
  end

  context '#pledge_currencies_code_symbol_pairs' do
    it 'should consist of string/symbol pairs' do
      subject.pledge_currencies_code_symbol_pairs.each do |pledge|
        expect(pledge.size).to eq 2
        expect(pledge.first).to be_a(String)
        expect(pledge.second).to be_a(String)
      end
    end
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
