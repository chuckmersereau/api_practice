require 'spec_helper'

RSpec.describe Constants::CurrencyList, type: :model do
  subject { Constants::CurrencyList.new }

  context '#currencies' do
    it { expect(subject.codes).to be_a Array }

    it 'should consist of ISO 4217 currency codes' do
      subject.codes.each do |currency|
        expect(currency).to match(/\A\w{3}\z/)
      end
    end
  end

  context '#id' do
    it { expect(subject.id).to be_blank }
  end
end
