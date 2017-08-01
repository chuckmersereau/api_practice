# Interacting with csv file contants mappings can be complex, this facade class exists to help make it easier.
#
# Csv file constants mappings can come from the client in two different formats:
#
#   1. Key value pairs:
#
#     {
#       likely_to_give: {
#         least_likely: ["not going to give"]
#       }
#     }
#
#
#   2. Id and values hashes:
#
#     {
#       likely_to_give: [
#         {
#           id: "Least Likely",
#           values: ["not going to give"]
#         }
#       ]
#     }
#
# In both cases, if we found the value "not going to give" in the csv column for likely_to_give then we would want to map it to the value "Least Likely".

class CsvFileConstantsMappingsFacade
  def initialize(csv_file_constants_mappings)
    @mappings = csv_file_constants_mappings
  end

  def header_ids
    mappings.keys
  end

  def convert_value(mpdx_constant_header, csv_constant_value)
    constant_mappings = mappings[mpdx_constant_header]
    csv_constant_value = '' if csv_constant_value.blank? # We don't want to handle nil, only empty strings.
    extract_mpdx_constant_value_from_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
  end

  def find_unsupported_constants_for_header_id(header_id)
    constant_mappings = mappings[header_id]

    if constant_mappings.is_a?(Hash)
      mapping_keys = constant_mappings.keys
      mapping_keys - CsvImport.constants[header_id].keys

    elsif constant_mappings.is_a?(Array)
      mapping_ids = constant_mappings.collect { |hash| hash.with_indifferent_access['id'] }
      mapping_ids - CsvImport.constants_hashes.find { |hash| hash.with_indifferent_access['id'] == header_id }&.[]('values')
    end
  end

  def find_mapped_values_for_header_id(header_id)
    constant_mappings = mappings[header_id]

    if constant_mappings.is_a?(Hash)
      constant_mappings.values.flatten

    elsif constant_mappings.is_a?(Array)
      constant_mappings.collect { |hash| hash.with_indifferent_access['values'] }.flatten
    end
  end

  private

  attr_accessor :mappings

  delegate :constants, to: CsvImport

  def extract_mpdx_constant_value_from_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
    if constant_mappings.is_a?(Hash)
      extract_mpdx_constant_value_from_key_value_pairs_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
    elsif constant_mappings.is_a?(Array)
      extract_mpdx_constant_value_from_id_and_values_hash_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
    end
  end

  def extract_mpdx_constant_value_from_key_value_pairs_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
    mpdx_constant_key = constant_mappings.find do |_, constant_mapping_values|
      [constant_mapping_values].flatten.include?(csv_constant_value)
    end&.first

    constants[mpdx_constant_header]&.[](mpdx_constant_key)
  end

  def extract_mpdx_constant_value_from_id_and_values_hash_mappings(constant_mappings, mpdx_constant_header, csv_constant_value)
    mpdx_constant_value = constant_mappings.find do |id_and_values_hash|
      id_and_values_hash['values']&.include?(csv_constant_value)
    end&.[]('id')

    constants[mpdx_constant_header]&.values&.include?(mpdx_constant_value) ? mpdx_constant_value : nil
  end
end
