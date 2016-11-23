class DonationReports::DonationInfoSerializer < ApplicationSerializer
  include LocalizationHelper
  alias symbol_for_currency_code currency_symbol

  attributes :amount,
             :contact_id,
             :converted_amount,
             :converted_currency,
             :converted_currency_symbol,
             :currency,
             :currency_symbol,
             :donation_date,
             :likelihood_type

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
