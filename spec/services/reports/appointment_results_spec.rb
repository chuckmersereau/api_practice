require 'rails_helper'

RSpec.describe Reports::AppointmentResults, type: :model do
  let(:account_list) { create(:account_list) }
  let(:report) { described_class.new(account_list: account_list, filter_params: {}) }

  describe 'initializes' do
    it 'initializes successfully' do
      expect(report).to be_a(Reports::AppointmentResults)
      expect(report.account_list).to eq account_list
    end

    it 'sets defaults' do
      expect(report.range).to eq '4w'
      expect(report.end_date).to eq Date.today
    end
  end

  describe '#periods_data' do
    context 'range of 2m' do
      before { report.filter_params[:range] = '2m' }
      around(:example) do |example|
        travel_to DateTime.new(2018, 4, 12, 12, 0, 0).getlocal, &example
      end

      it 'creates two month-long periods' do
        expect(Reports::AppointmentResultsPeriod).to receive(:new).with(account_list: account_list,
                                                                        start_date: Date.new(2018, 3, 1).beginning_of_day,
                                                                        end_date: Date.new(2018, 3, 31).end_of_day)
        expect(Reports::AppointmentResultsPeriod).to receive(:new).with(account_list: account_list,
                                                                        start_date: Date.new(2018, 4, 1).beginning_of_day,
                                                                        end_date: Date.new(2018, 4, 30).end_of_day)

        report.periods_data
      end
    end

    it 'takes thread timezone into account'
  end

  describe '#meta' do
    it 'returns a summary of averages' do
      i = -1
      monthly_increase_periods = [71, 50, 70, 51]
      period_double = double('period', individual_appointments: 3,
                                       group_appointments: 1,
                                       new_monthly_partners: 1,
                                       new_special_pledges: 1,
                                       pledge_increase: 1)
      allow(period_double).to receive(:monthly_increase) { monthly_increase_periods[i += 1] }
      allow(Reports::AppointmentResultsPeriod).to receive(:new).and_return(period_double)

      # the average is 60.5, but we expect it to round up
      expect(report.meta['average_monthly_increase']).to be 61
    end

    it 'only averages requested fields' do
      meta = report.meta('reports_appointment_results_periods' => ['monthly_increase'])

      expect(meta.keys).to eq ['average_monthly_increase']
    end
  end
end
