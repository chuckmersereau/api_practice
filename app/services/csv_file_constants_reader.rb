# This service object will read a CSV file and extract the unique values in each column.
# The purpose is to help map values in a user's CSV file to MPDX constants.
# Columns are ignored if they obviously aren't constants (like "name"), so not every column is returned.
# There is also a max number of values returned per column, to prevent an excessively large response.

class CsvFileConstantsReader
  MAX_MAPPINGS_PER_HEADER = 100
  EXCLUDE_HEADERS_CONTAINING_STRINGS = %w(
    address
    church
    city
    country
    mail
    metro
    name
    note
    phone
    postal
    province
    referred
    region
    state
    street
    tags
    website
    zip
  ).freeze

  def initialize(file_path)
    self.file_path = file_path
    self.constants_hash = Hash.new { |hash, key| hash[key] = Set.new }
  end

  def constants
    build_constant_sets
    constants_hash
  end

  private

  attr_accessor :file_path, :constants_hash, :headers

  def build_constant_sets
    @headers = nil

    CsvFileReader.new(file_path).each_row do |csv_row|
      @headers ||= csv_row.headers

      csv_row.fields.each_with_index do |value, index|
        header = headers[index]&.parameterize&.underscore
        next if exclude_column_with_header?(header)
        constant_set = constants_hash[header]
        value = '' if value.blank? # Use empty strings instead of nil
        constant_set << value if constant_set.size < MAX_MAPPINGS_PER_HEADER
      end
    end
  end

  def exclude_column_with_header?(header)
    return true if header.blank?
    header = header.to_s.downcase
    EXCLUDE_HEADERS_CONTAINING_STRINGS.any? { |substring| header.include?(substring) }
  end
end
