class DonationReports::DonationInfoSerializer < ServiceSerializer
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

  delegate :contact_id,
           :converted_amount,
           :converted_currency,
           :currency,
           :donation_date,
           :likelihood_type,
           to: :object

  def amount
    object.amount.to_f
  end

  def currency_symbol
    symbol_for_currency_code(object.currency)
  end

  def converted_currency_symbol
    return nil unless object.converted_currency
    symbol_for_currency_code(object.converted_currency)
  end
end
