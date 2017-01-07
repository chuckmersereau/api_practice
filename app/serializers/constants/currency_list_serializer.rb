class Constants::CurrencyListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  type :currency_list
  attributes :currencies

  def currencies
    currencies_exhibit.codes.map do |code|
      [currencies_exhibit.currency_code_and_symbol(code), code]
    end
  end

  def currencies_exhibit
    @currencies_exhibit ||= exhibit(object)
  end
end
