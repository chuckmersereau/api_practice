require 'rails_helper'

describe Concerns::Reports::DateRangeFilterable do
  class DefaultSample
    include Concerns::Reports::DateRangeFilterable

    def filter_params
      {}
    end
  end

  class SpecificSample
    include Concerns::Reports::DateRangeFilterable

    def filter_params
      { month_range: ((Date.today - 3.years)..(Date.today - 1.year)) }
    end
  end

  class InvalidSample
    include Concerns::Reports::DateRangeFilterable

    def filter_params
      { month_range: ((Date.today - 1.year)..(Date.today - 3.years)) }
    end
  end

  let(:default_start_date) { 12.months.ago.to_date.beginning_of_month }
  let(:three_years_ago) { Date.today - 3.years }
  let(:one_year_ago) { Date.today - 1.year }
  let(:specific_sample_dates) { (three_years_ago..one_year_ago) }
  let(:invalid_sample_date) { (one_year_ago..three_years_ago) }
  let(:specific_sample) { SpecificSample.new }
  let(:invalid_sample) { InvalidSample.new }

  it 'should have a default number of months back' do
    expect(Concerns::Reports::DateRangeFilterable::MONTHS_BACK).to eq(12)
  end

  it 'should get a default end date' do
    expect(DefaultSample.new.end_date).to eq(Date.today)
  end

  it 'should get a default start date' do
    expect(DefaultSample.new.start_date).to eq(default_start_date)
  end

  it 'should get a specified start date' do
    expect(specific_sample.start_date).to eq(three_years_ago.beginning_of_month)
  end

  it 'should get a specified end date' do
    expect(specific_sample.end_date).to eq(specific_sample_dates.last)
  end

  it 'should handle cases where the start date is after the end date' do
    date = invalid_sample.end_date.beginning_of_month - InvalidSample::MONTHS_BACK.months
    expect(invalid_sample.start_date).to eq(date)
  end

  it 'should build an array of dates that are all the beginning of the month' do
    expect(specific_sample.months.size).to eq(25)
  end
end
