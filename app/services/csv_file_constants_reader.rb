# This service object will read a CSV file and extract the unique values in each column.
# The purpose is to help map values in a user's CSV file to MPDX constants.
# Columns are ignored if they obviously aren't constants (like "name"), so not every column is returned.
# There is also a max number of values returned per column, to prevent an excessively large response.

require 'csv'

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

  def initialize(file_contents)
    self.csv = CSV.new(file_contents)
    self.constants_hash = Hash.new { |hash, key| hash[key] = Set.new }
  end

  def constants
    csv.rewind
    self.headers = csv.first
    build_constant_sets
    constants_hash
  end

  private

  attr_accessor :file_path, :constants_hash, :csv, :headers

  def build_constant_sets
    csv.each do |row|
      row.each_with_index do |value, index|
        header = headers[index]
        next if exclude_column_with_header?(header)
        constant_set = constants_hash[header]
        constant_set << value if constant_set.size < MAX_MAPPINGS_PER_HEADER
      end
    end
  end

  def exclude_column_with_header?(header)
    return nil if header.blank?
    header = header.downcase
    EXCLUDE_HEADERS_CONTAINING_STRINGS.any? { |substring| header.include?(substring) }
  end
end
