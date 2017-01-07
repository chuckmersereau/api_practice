class CurrencyListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'Constants::CurrencyList'
  end

  def currency_code_and_symbol(code)
    format '%s (%s)', code, currency_symbol(code)
  end
end
