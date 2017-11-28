# This class takes in import.file_constants_mappings on its initializer
# It simplifies conversion of CSV values to MPDX Constants and ensures
# there are no values mapped incorrectly
class CsvValueToConstantMappings
  attr_accessor :mappings

  def initialize(mappings)
    @mappings = mappings.with_indifferent_access
  end

  def constant_names
    mappings.keys
  end

  def convert_value_to_constant_id(constant_name, value)
    constant_hash = find_constant_hash(constant_name, value)

    return unless constant_hash
    return constant_hash['key'] if constant_name == 'pledge_frequency'
    constant_hash['id']
  end

  def find_unsupported_constants(constant_name)
    mapping_ids = mappings[constant_name].collect { |hash| hash['id'] }.flatten
    mapping_ids - (CsvImport.constants.with_indifferent_access[constant_name].map { |constant| constant['id'] } | [''])
  end

  def find_mapped_values(constant_name)
    mappings[constant_name].collect { |hash| hash.with_indifferent_access['values'] }.flatten
  end

  protected

  def find_constant_hash(constant_name, value)
    value = '' if value.blank?
    constant_id = find_constant_id_from_value(mappings[constant_name] || {}, value)

    CsvImport.constants.with_indifferent_access[constant_name]&.find do |constant|
      constant['id'] == constant_id
    end
  end

  def find_constant_id_from_value(mapping, value)
    mapping.find do |object|
      object['values']&.include?(value)
    end.try(:[], 'id')
  end
end
