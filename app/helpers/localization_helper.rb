module LocalizationHelper
  def number_to_current_currency(value, options = {})
    options[:precision] ||= 0
    options[:currency] ||= current_currency
    options[:locale] ||= locale
    begin
      value.to_f.localize(options[:locale]).to_currency.to_s(options)
    rescue Errno::ENOENT
      value.to_f.localize(:es).to_currency.to_s(options)
    end
  end

  def current_currency()
    @current_currency ||= current_account_list.default_currency
  end
end
