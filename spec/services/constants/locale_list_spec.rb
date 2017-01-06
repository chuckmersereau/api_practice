require 'spec_helper'

RSpec.describe Constants::LocaleList, type: :model do
  subject { Constants::LocaleList.new }

  context '#locales' do
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

  context '#id' do
    it { expect(subject.id).to be_blank }
  end
end
