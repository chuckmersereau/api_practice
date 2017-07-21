class UpdatableOnlyWhenSourceIsMpdxValidator < ActiveModel::EachValidator
  # Since classic still needs to be supported, manual must be added to the list of valid sources,
  # however this should be removed once we stop supporting classic.

  VALID_SOURCES = %w(MPDX manual).freeze

  def validate_each(record, attribute, _value)
    return if !record.persisted? || VALID_SOURCES.include?(record.source) || record.changes[attribute].blank?
    record.errors[attribute] << 'cannot be changed because the source is not MPDX'
  end
end
