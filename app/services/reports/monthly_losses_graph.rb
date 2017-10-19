class Reports::MonthlyLossesGraph < ActiveModelSerializers::Model
  MONTH_FORMAT = '%b %Y'.freeze

  attr_accessor :account_list, :months, :today

  def initialize(attributes = {})
    super

    @today = Time.zone.today unless attributes.key?(:today)
  end

  # @return [Hash<String, Float>] The same as #losses, but each key is the name
  #   of the month in question
  def losses_with_month_names
    Hash[month_names.zip(losses)]
  end

  # @return [Array<String>] the month represented by each element in #losses
  def month_names
    Array.new(months_count) do |index|
      (start_month + (index + 1).months).strftime(MONTH_FORMAT)
    end
  end

  # @return [Array<Float>] the month-over-month decrease in balance, over the
  #   last #months_count months.
  def losses
    monthly_differences.map { |diff| diff.zero? ? diff : diff * -1 }
  end

  private

  # @return [Array<Float>] the change in balance from the previous month
  def monthly_differences
    month_totals.each_cons(2)
                .map { |prev_total, new_total| new_total - prev_total }
                .map { |total| total.round(2) }
  end

  # @return [Array<Float>]
  def month_totals
    month_balances.map { |arr| arr.inject(0) { |a, e| a + e.balance } }
  end

  # @return [Array<Array<Balance>>]
  def month_balances
    @month_balances ||= Array.new(months_count + 1) { [] }.tap do |months|
      balances.each do |balance|
        months[month_index(balance.created_at)] << balance
      end
    end
  end

  def balances
    @balances ||= account_list.balances.where('balances.created_at >= ?',
                                              start_month)
  end

  def month_index(date)
    (date.year * 12 + date.month) - (start_month.year * 12 + start_month.month)
  end

  # Note that the start is one month earlier than the first month in our report,
  # so we can return the loss from the first element's previous month
  def start_month
    @start_month ||= today.beginning_of_month - months_count.months
  end

  def months_count
    @months_count ||=
      if months.to_i.positive?
        months.to_i
      else
        SHARED_DATE_CONSTANTS['DEFAULT_MONTHLY_LOSSES_COUNT']
      end
  end
end
