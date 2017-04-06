class TntImport::XmlReader
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
    xml = {}
    begin
      File.open(file_path, 'r:utf-8') do |file|
        contents = file.read
        begin
          xml = Hash.from_xml(contents)
        rescue => e
          # If the document contains characters that we don't know how to parse
          # just strip them out.
          # The eval is dirty, but it was all I could come up with at the time
          # to unescape a unicode character.
          begin
            bad_char = e.message.match(/"([^"]*)"/)[1]
            contents.gsub!(eval(%("#{bad_char}")), ' ') # rubocop:disable Eval
          rescue
            raise e
          end
          retry
        end
      end
    rescue ArgumentError
      File.open(file_path, 'r:windows-1251:utf-8') do |file|
        xml = Hash.from_xml(file.read)
      end
    end
    xml
  end
end
