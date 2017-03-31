class TntImport::Xml
  delegate :present?, :blank?, to: '@xml'

  def initialize(xml)
    @xml = xml
  end

  def tables
    @xml&.dig('Database', 'Tables')
  end

  def version
    @xml&.dig('Database', 'Version')&.to_f
  end
end
