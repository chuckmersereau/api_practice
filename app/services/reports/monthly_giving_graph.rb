class Reports::MonthlyGivingGraph < ActiveModelSerializers::Model
  attr_accessor :account_list,
                :filter_params,
                :locale

  attr_writer :display_currency

  delegate :monthly_goal, to: :account_list

  def initialize(attributes)
    super
    self.filter_params ||= {}
  end

  def totals
    currencies.map(&method(:totals_for_currency))
              .sort_by { |totals| totals[:total_converted] }
              .reverse
  end

  def pledges
    account_list.total_pledges.to_i
  end

  def monthly_average
    total_converted.sum.fdiv(number_of_months_in_range).to_i
  end

  def months_to_dates
    filter_params[:donation_date].select { |d| d.day == 1 }
  end

  def salary_currency
    account_list.salary_currency_or_default
  end

  def display_currency
    @display_currency || salary_currency
  end

  def multi_currency
    account_list.multi_currency?
  end

  def filter_params=(filter_params)
    filter_params.delete(:account_list_id)
    filter_params[:donation_date] = 11.months.ago.beginning_of_month.to_date..Date.today.end_of_month unless filter_params[:donation_date]
    @filter_params = filter_params
  end

  protected

  def total_converted
    return total_converted_by_month_excluding_last_month if end_date == Date.today.end_of_month
    total_converted_by_month
  end

  def total_converted_by_month_excluding_last_month
    totals.map { |t| t[:month_totals][0...-1].map { |m| m[:converted] }.sum }
  end

  def total_converted_by_month
    totals.map { |t| t[:total_converted] }
  end

  def number_of_months_in_range
    (end_date.year * 12 + end_date.month) -
      (start_date.year * 12 + start_date.month) +
      (end_date == Date.today.end_of_month ? 0 : 1)
  end

  def start_date
    filter_params[:donation_date].first
  end

  def end_date
    filter_params[:donation_date].end
  end

  def currencies
    # It is possible for some donations to have a `nil` value for their
    # currency, but that that is a rarer case and something we should fix
    # earlier in the process than here. What we do to handle that case is to
    # just ignore donations with no currencies to prevent an invalid call on
    # `nil` in the chart itself.
    @currencies ||= donation_scope.currencies.select(&:present?)
  end

  def totals_for_currency(currency)
    month_totals = currency_month_totals(currency)

    {
      currency: currency,
      total_amount: month_totals.map { |t| t[:amount] }.sum,
      total_converted: month_totals.map { |t| t[:converted] }.sum,
      month_totals: month_totals
    }
  end

  def currency_month_totals(currency)
    filter_params[:donation_date].select { |d| d.day == 1 }.map do |start_date|
      end_date = start_date.end_of_month
      amount = donation_scope.where(donation_date: start_date..end_date)
                             .where(currency: currency)
                             .sum(:amount)

      mid_month = Date.new(start_date.year, start_date.month, 15)
      converted = CurrencyRate.convert_on_date(amount: amount, from: currency,
                                               to: display_currency, date: mid_month)

      { amount: amount, converted: converted }
    end
  end

  def donation_scope
    account_list.donations.where(filter_params)
  end
end
