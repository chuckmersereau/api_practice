require 'nokogiri'
require 'csv'

module EncodingUtil
  def normalized_utf8(contents)
    contents = contents.to_s
    return '' if contents == ''

    encoding_info = CharlockHolmes::EncodingDetector.detect(contents)
    return nil unless encoding_info
    encoding = encoding_info[:encoding]
    contents = CharlockHolmes::Converter.convert(contents, encoding, 'UTF-8')

    # Remove byte order mark
    contents.sub!("\xEF\xBB\xBF".force_encoding('UTF-8'), '')

    contents.encode(universal_newline: true)
  end

  module_function :normalized_utf8
end
