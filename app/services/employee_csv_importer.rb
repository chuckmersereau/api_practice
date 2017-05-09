require 'csv'
require 'ostruct'

class EmployeeCsvImporter
  REQUIRED_HEADERS = %w(
    email
    first_name
    last_name
    relay_guid
    key_guid
  ).freeze

  attr_reader :import_group_size,
              :path

  def initialize(path:, import_group_size: nil)
    @path = path
    @import_group_size = import_group_size || default_import_group_size
  end

  def converted_data
    @converted_data ||= convert_row_data
  end

  def default_import_group_size
    180
  end

  def import(from:, to:)
    converted_data[from..to].each do |user_for_import|
      cas_attributes = user_for_import.cas_attributes

      UserFromCasService.find_or_create(cas_attributes)
    end
  end

  def queue!
    range_groups = (0...converted_data.count).each_slice(import_group_size)

    range_groups.each_with_index do |range_group, index|
      from = range_group.first
      to   = range_group.last

      EmployeeCsvGroupImportWorker.perform_in(index.hours, path, from, to)
    end
  end

  def row_data
    @row_data ||= fetch_row_data
  end

  def self.import(path:, from:, to:)
    new(path: path).import(from: from, to: to)
  end

  def self.queue(path:, import_group_size: nil)
    new(path: path, import_group_size: import_group_size).queue!
  end

  private

  def convert_row_data
    row_data.map do |single_row|
      attrs = single_row.to_h.keep_if { |key, _| key.present? }

      UserForImport.new(attrs)
    end
  end

  def csv_options
    {
      col_sep: ',',
      headers: true
    }
  end

  def fetch_row_data
    file    = open(path)
    data    = CSV.read(file, csv_options)
    headers = data.first.to_h.keys.compact

    unless REQUIRED_HEADERS.all? { |required_header| headers.include?(required_header) }
      raise InvalidHeadersError, invalid_headers_error(headers)
    end

    data
  end

  def invalid_headers_error(wrong_headers)
    required_headers_list = REQUIRED_HEADERS.join(', ')
    wrong_headers_list    = wrong_headers.join(', ')

    "Your CSV file must have the headers: #{required_headers_list}, instead it has: #{wrong_headers_list}"
  end

  class UserForImport < OpenStruct
    def cas_attributes
      {
        email: email,
        firstName: first_name,
        lastName: last_name,
        relayGuid: relay_guid || '',
        ssoGuid: key_guid || '',
        theKeyGuid: key_guid || ''
      }
    end
  end

  class InvalidHeadersError < StandardError; end
end
