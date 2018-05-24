class Reports::Base < ActiveModelSerializers::Model
  attr_accessor :account_list
  attr_writer :filter_params

  def periods_data
    @periods_data ||= periods.map do |period|
      generate_report_for_period(period)
    end
  end

  def filter_params
    @filter_params || {}
  end

  def end_date
    filter_params[:end_date].presence || Date.today
  end

  def range
    filter_params[:range].presence || default_range
  end

  protected

  def default_range
    '4w'
  end

  def generate_report_for_period(*)
    raise NotImplementedError, 'Report must extend generate_report_for_period'
  end

  private

  def periods
    Array.new(times) do |i|
      period_end_date = end_date - i.send(time_unit)
      {
        start_date: period_end_date.send("beginning_of_#{time_unit}").beginning_of_day,
        end_date: period_end_date.send("end_of_#{time_unit}").end_of_day
      }
    end
  end

  def times
    range.to_i
  end

  def time_unit
    case range[-1]
    when 'd'
      :day
    when 'w'
      :week
    when 'm'
      :month
    when 'y'
      :year
    end
  end

  def valid_range
    range =~ /^\d+[dwmy]$/
  end
end
