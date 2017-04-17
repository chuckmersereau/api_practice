class TntImport::Xml
  delegate :present?, :blank?, to: '@xml'

  def initialize(xml)
    @xml = xml
  end

  def table_names
    @table_names ||= @xml.css('Database > Tables > *').map(&:name)
  end

  def tables
    @tables ||= table_names.each_with_object({}) do |table_name, hash|
      hash[table_name] = table(table_name)
    end
  end

  def table(name)
    @xml.css("Database > Tables > #{name} > row").lazy.map(&method(:parse_row))
  end

  def version
    @xml.at_css('Database > Version').content.to_f
  end

  private

  def parse_row(row)
    {
      'id' => row.attr('id')
    }.merge(extract_row_columns(row))
  end

  def extract_row_columns(row)
    Hash[
      row.element_children.map { |column| [column.name, column.content] }
    ]
  end
end
