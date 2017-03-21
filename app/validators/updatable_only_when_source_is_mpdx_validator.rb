class UpdatableOnlyWhenSourceIsMpdxValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    return if !record.persisted? || record.source == 'MPDX' || record.changes[attribute].blank?
    record.errors[attribute] << 'cannot be changed because the source is not MPDX'
  end
end
