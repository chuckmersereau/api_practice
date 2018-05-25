class Reports::PledgeIncreaseContact < ActiveModelSerializers::Model
  attr_accessor :contact, :beginning, :end_status

  def beginning_converted
    convert(beginning_monthly, beginning_currency)
  end

  def beginning_monthly
    pledge_from_status(beginning)
  end

  def beginning_currency
    beginning.try(:[], 'pledge_currency') || default_currency
  end

  def end_converted
    convert(end_monthly, end_currency)
  end

  def end_monthly
    # use current contact values if there have been no changes since the end of the window
    pledge_from_status(end_status || contact)
  end

  def end_currency
    (end_status || contact).pledge_currency
  end

  def increase_amount
    @increase_amount ||= (end_converted - beginning_converted)
  end

  private

  def convert(amount, currency)
    CurrencyRate.convert_with_latest(amount: amount, from: currency, to: default_currency)
  end

  def default_currency
    @default_currency = contact.account_list.salary_currency_or_default
  end

  def pledge_from_status(status)
    return 0 unless status&.status == 'Partner - Financial'

    status.pledge_amount.to_i / (status.pledge_frequency || 1)
  end
end
