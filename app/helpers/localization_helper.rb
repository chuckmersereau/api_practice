module LocalizationHelper
  def number_to_current_currency(value, options = {})
    options[:precision] ||= 0
    options[:currency] ||= current_currency
    options[:locale] ||= locale

    amount_with_symbol = format_with_currency_options(value, options)
    currency_code_or_blank = (options[:show_code] ? " #{options[:currency]}" : '')

    amount_with_symbol + currency_code_or_blank
  end

  def current_currency(account_list = nil)
    unless @current_currency
      account_list ||= current_account_list
      @current_currency = account_list ? account_list.default_currency : 'USD'
    end
    @current_currency
  end

  def currency_options(account_list)
    Hash[account_list.currencies.map do |currency|
      [currency, currency_with_symbol(currency)]
    end.compact]
  end

  def currency_with_symbol(currency)
    "#{currency} (#{currency_symbol(currency)})"
  end

  def currency_symbol(currency_code)
    info = TwitterCldr::Shared::Currencies.for_code(currency_code)
    info ? info[:symbol] : currency_code
  end

  private

  def format_with_currency_options(value, options)
    value.to_f.localize(options[:locale]).to_currency.to_s(options)
  rescue Errno::ENOENT
    # If a bad locale is passed in, fall back to using the spanish currency
    # locale because it's probably the most common format globally speaking.
    value.to_f.localize(:es).to_currency.to_s(options)
  end
end
