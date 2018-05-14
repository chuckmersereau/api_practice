require 'rails_helper'

RSpec.describe Reports::PledgeHistories, type: :model do
  let(:account_list) { create(:account_list) }
  subject { described_class.new(account_list: account_list, filter_params: {}) }

  describe 'initializes' do
    it 'initializes successfully' do
      expect(subject).to be_a(described_class)
      expect(subject.account_list).to eq account_list
    end

    it 'sets defaults' do
      expect(subject.range).to eq '13m'
      expect(subject.end_date).to eq Date.today
    end
  end

  describe '#periods_data' do
    context 'range of 2m' do
      before { subject.filter_params[:range] = '2m' }
      around(:example) do |example|
        travel_to DateTime.new(2018, 4, 12, 12, 0, 0), &example
      end

      it 'creates two month-long periods' do
        expect(Reports::PledgeHistoriesPeriod).to receive(:new).with(
          account_list: account_list,
          start_date: Date.new(2018, 3, 1).beginning_of_day,
          end_date: Date.new(2018, 3, 31).end_of_day
        )
        expect(Reports::PledgeHistoriesPeriod).to receive(:new).with(
          account_list: account_list,
          start_date: Date.new(2018, 4, 1).beginning_of_day,
          end_date: Date.new(2018, 4, 30).end_of_day
        )
        subject.periods_data
      end
    end
  end
end
