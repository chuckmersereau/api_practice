# This validator makes sure that the client has provided accurate and sufficient mappings for their CSV import.
# The mapping validation is intentionally aggressive to help prevent any possible issues during the import.

class CsvImportMappingsValidator < ActiveModel::Validator
  def validate(import)
    self.import = import
    self.csv_import = CsvImport.new(import)
    return if (import.errors.keys & [:file_constants_mappings, :file_headers_mappings]).present?
    self.file_constants_mappings = CsvValueToConstantMappings.new(import.file_constants_mappings)

    file_headers_mappings_contains_required_headers
    file_headers_mappings_contains_only_supported_headers
    file_headers_mappings_only_maps_to_headers_in_the_file
    return if import.errors.keys.include?(:file_headers_mappings)

    file_constants_mappings_contains_the_constants_needed_for_import
    file_constants_mappings_only_maps_constants_that_are_supported
    file_constants_mappings_only_maps_constants_that_are_also_in_file_headers_mappings
    return if import.errors.keys.include?(:file_constants_mappings)

    file_constants_mappings_only_maps_constants_to_values_found_in_the_csv
    file_constants_mappings_maps_all_constants_values_found_in_the_csv
  end

  private

  attr_accessor :import, :csv_import, :file_constants_mappings

  def file_headers_mappings_contains_required_headers
    return if CsvImport.required_headers.keys.blank?

    return unless (CsvImport.required_headers.keys.map(&:to_s) & import.file_headers_mappings.keys).empty?

    import.errors[:file_headers_mappings] << "should specify a header mapping for at least one of the required headers. The required headers are: #{CsvImport.required_headers.keys}"
  end

  def file_headers_mappings_contains_only_supported_headers
    return if (import.file_headers_mappings.keys & CsvImport.supported_headers.keys.map(&:to_s)) == import.file_headers_mappings.keys

    unsupported_keys = import.file_headers_mappings.keys - CsvImport.supported_headers.keys.map(&:to_s)
    import.errors[:file_headers_mappings] << 'has unsupported headers. One or more of the headers specified in file_headers_mappings is not supported, ' \
                                             'please refer to the constants endpoints for a list of supported headers. ' \
                                             "The unsupported headers you specifed are #{unsupported_keys}"
  end

  def file_headers_mappings_only_maps_to_headers_in_the_file
    return if (import.file_headers_mappings.values & import.file_headers.keys) == import.file_headers_mappings.values.uniq

    invalid_headers = import.file_headers_mappings.values - import.file_headers.keys
    import.errors[:file_headers_mappings] << 'has unsupported mappings. One or more of the header mappings was not found in the headers of the given CSV file, ' \
                                             'refer to attribute "file_headers" for a list of headers extracted from the given file. ' \
                                             "The invalid headers are: #{invalid_headers}"
  end

  def file_constants_mappings_contains_the_constants_needed_for_import
    constants_needing_to_be_imported = (CsvImport.constants.keys.map(&:to_s) & import.file_headers_mappings.keys)
    return if (constants_needing_to_be_imported & file_constants_mappings.constant_names) == constants_needing_to_be_imported

    missing_constant_mappings = constants_needing_to_be_imported - file_constants_mappings.constant_names
    import.errors[:file_constants_mappings] << 'is missing mappings. One or more of the header constants specified in file_headers_mappings ' \
                                               'does not have a mapping specified in file_constants_mappings. ' \
                                               "The missing constant mappings are: #{missing_constant_mappings}"
  end

  def file_constants_mappings_only_maps_constants_that_are_supported
    file_constants_mappings.constant_names.each do |header_id|
      unless CsvImport.supported_headers.keys.map(&:to_s).include?(header_id)
        import.errors[:file_constants_mappings] << %(has an invalid mapping. You cannot map to the constant "#{header_id}" because it's not a supported MPDX constant.)
        next
      end

      unsupported_constants = file_constants_mappings.find_unsupported_constants(header_id)
      next if unsupported_constants.blank?
      import.errors[:file_constants_mappings] << %(has an invalid mapping. For the header "#{header_id}", you cannot map to the constants: #{unsupported_constants})
    end
  end

  def file_constants_mappings_only_maps_constants_that_are_also_in_file_headers_mappings
    return if (file_constants_mappings.constant_names & import.file_headers_mappings.keys) == file_constants_mappings.constant_names

    invalid_mapping_keys = file_constants_mappings.constant_names - import.file_headers_mappings.keys
    import.errors[:file_constants_mappings] << "has an invalid mapping. You cannot map to the constants #{invalid_mapping_keys} because they are not found in file_headers_mappings"
  end

  def file_constants_mappings_only_maps_constants_to_values_found_in_the_csv
    file_constants_mappings.constant_names.each do |header_id|
      mapping_values = file_constants_mappings.find_mapped_values(header_id)
      file_constants = csv_import.file_constants_for_mpdx_header(header_id)
      next if (mapping_values & file_constants) == mapping_values.uniq

      invalid_mapping_values = mapping_values - file_constants
      import.errors[:file_constants_mappings] << %(has an invalid mapping. For the header "#{header_id}", we couldn't find the following values in the CSV: #{invalid_mapping_values})
    end
  end

  def file_constants_mappings_maps_all_constants_values_found_in_the_csv
    constants_needing_to_be_imported = (CsvImport.constants.keys.map(&:to_s) & import.file_headers_mappings.keys)

    constants_needing_to_be_imported.each do |constant_header|
      mapped_constants = file_constants_mappings.find_mapped_values(constant_header)
      file_constants = csv_import.file_constants_for_mpdx_header(constant_header)
      next if (file_constants & mapped_constants) == file_constants

      missing_mappings = file_constants - mapped_constants
      import.errors[:file_constants_mappings] << %(is missing mappings. For the header "#{constant_header}", we couldn't find the following mappings to the CSV values: #{missing_mappings})
    end
  end
end
