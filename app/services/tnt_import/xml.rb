class TntImport::Xml
  attr_reader :table_names,
              :tables,
              :version

  def initialize(xml)
    @table_names = xml.css('Database > Tables > *').map(&:name)

    @tables = @table_names.each_with_object({}) do |table_name, hash|
      hash[table_name] = xml.css("Database > Tables > #{table_name} > row").map(&method(:parse_row))
    end

    @version = xml.at_css('Database > Version').content.to_f
  end

  def table(name)
    tables[name]
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
