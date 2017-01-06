class Constants::LocaleList
  alias read_attribute_for_serialization send

  def locales
    @locales ||= locales_hash.invert.sort_by(&:first)
  end

  def id
  end

  private

  def locales_hash
    TwitterCldr::Shared::Languages
      .all
      .select { |k, _| TwitterCldr.supported_locales.include?(k) }
  end
end
