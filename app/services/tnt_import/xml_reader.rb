class TntImport::XmlReader
  def initialize(import)
    @import = import
  end

  def parsed_xml
    xml = read_xml(@import.file.file.file)
    xml['Database']['Tables'] if xml.present? && xml['Database']
  end

  private

  def read_xml(import_file)
    xml = {}
    begin
      File.open(import_file, 'r:utf-8') do |file|
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
      File.open(import_file, 'r:windows-1251:utf-8') do |file|
        xml = Hash.from_xml(file.read)
      end
    end
    xml
  end
end
