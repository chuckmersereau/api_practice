class FileSizeValidator < ActiveModel::Validator
  MAX_FILE_SIZE_IN_BYTES = 10_000_000

  def validate(record)
    return unless record&.file&.size
    return if record.file.size <= MAX_FILE_SIZE_IN_BYTES
    record.errors[:base] << _('File size must be less than %{size} bytes').localize % { size: MAX_FILE_SIZE_IN_BYTES }
  end
end
