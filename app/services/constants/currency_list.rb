class Constants::CurrencyList
  alias read_attribute_for_serialization send

  def codes
    @codes ||= TwitterCldr::Shared::Currencies.currency_codes
  end

  def id
  end
end
