class TntImport::XmlReader
  UNPARSABLE_UTF8_CHARACTERS = [
    "\u0000" # "null" character
  ].freeze

  def initialize(import)
    @import = import
  end

  def parsed_xml
    TntImport::Xml.new(read_xml)
  end

  private

  def file_path
    @import.file.cache_stored_file!
    @import.file.path
  end

  def read_xml
    contents = File.open(file_path, 'r:utf-8').read
    UNPARSABLE_UTF8_CHARACTERS.each do |unparsable_utf8_character|
      contents.gsub!(unparsable_utf8_character, '')
    end
    Nokogiri::XML(contents)
  rescue ArgumentError => exception
    Rollbar.info(exception)
    contents = File.open(file_path, 'r:windows-1251:utf-8').read
    Nokogiri::XML(contents)
  end
end
