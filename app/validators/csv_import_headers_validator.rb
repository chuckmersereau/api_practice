class CsvImportHeadersValidator < ActiveModel::Validator
  def validate(import)
    return unless import.file.present? # will be blank if extension is wrong

    csv_import = CsvImport.new(import)

    actual = csv_import.actual_headers || []

    missing = CsvImport::REQUIRED_HEADERS - actual
    extra = actual - CsvImport::SUPPORTED_HEADERS

    if missing.present? || extra.present?
      import.errors[:base] << _('<b>Your CSV import has invalid headers.</b> The headers and format must exactly match the sample.')
    end

    if extra.present?
      import.errors[:base] << _('<b>Incorrect headers you specified:</b> ') + extra.join(', ')
    end

    if missing.present?
      import.errors[:base] << _('<b>Missing required headers:</b> ') + missing.join(', ')
    end
  end
end
