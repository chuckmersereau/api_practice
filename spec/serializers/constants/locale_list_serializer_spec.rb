require 'spec_helper'

describe Constants::LocaleListSerializer do
  subject { Constants::LocaleListSerializer.new(locale_list) }
  let(:locale_list) { Constants::LocaleList.new }

  context '#locales' do
    it 'should be an array' do
      expect(subject.locales).to be_an Array
    end

    it 'should consist of string/symbol pairs' do
      subject.locales.each do |locale|
        expect(locale.size).to eq 2
        expect(locale.first).to be_a(String)
        expect(locale.second).to be_a(Symbol)
      end
    end

    it 'should have a name with the locale code in parentheses' do
      subject.locales.each do |locale|
        expect(locale.first).to match(/\A[^\(]+\(\w+(?:-\w+)?\)\z/)
      end
    end

    it 'should have ISO 3166-1 alpha-2 codes' do
      subject.locales.each do |locale|
        expect(locale.second).to match(/\w\w/)
      end
    end
  end

  context '#locales_exhibit' do
    it { expect(subject.locales_exhibit).to be_a LocaleListExhibit }
  end
end
