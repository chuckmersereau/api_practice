class DonationReports::DonationInfoSerializer < ActiveModel::Serializer
  include LocalizationHelper
  alias symbol_for_currency_code currency_symbol

  attributes(*(DonationReports::DonationInfo::ATTRIBUTES +
               [:currency_symbol, :converted_currency_symbol]))

  def currency_symbol
    symbol_for_currency_code(object.currency)
  end

  def converted_currency_symbol
    symbol_for_currency_code(object.converted_currency)
  end

  def converted_amount
    object.converted_amount.to_f
  end

  def amount
    object.amount.to_f
  end
end
