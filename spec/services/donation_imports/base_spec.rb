require 'rails_helper'

RSpec.describe DonationImports::Base do
  let(:organization_account) { double(:organization_account) }

  before { allow(organization_account).to receive(:organization) }

  subject { described_class.new(organization_account) }

  describe '#parse_date' do
    it 'parse the date string given as argument' do
      expect(subject.parse_date('11/15/2001')).to eq(Date.new(2001, 11, 15))
      expect(subject.parse_date('2001-11-15')).to eq(Date.new(2001, 11, 15))
    end

    it 'returns the date when given a datetime object' do
      expect(subject.parse_date(Date.new(2001, 11, 15))).to eq(Date.new(2001, 11, 15))
      expect(subject.parse_date(Time.new(2001, 11, 15))).to eq(Date.new(2001, 11, 15))
      expect(subject.parse_date(DateTime.new(2001, 11, 15))).to eq(Date.new(2001, 11, 15))
    end

    it 'rescues Argument errors when parsing' do
      expect(subject.parse_date('invalid address')).to eq(nil)
    end
  end
end
