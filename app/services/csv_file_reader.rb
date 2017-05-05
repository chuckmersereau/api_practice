require 'csv'

class CsvFileReader
  def initialize(file_path)
    @file_path = file_path
  end

  def each_row
    csv_contents = File.read(@file_path)
    csv_contents = EncodingUtil.normalized_utf8(csv_contents)
    CSV.new(csv_contents, headers: true).each do |csv_row|
      next if csv_row.fields.compact.blank? # Skip this row if it's blank.
      yield(csv_row)
    end
  end
end
