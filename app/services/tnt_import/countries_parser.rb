class TntImport::CountriesParser
  class << self
    def countries_by_tnt_id(xml)
      return {} unless xml&.tables.dig('Country').present?
      Hash[tnt_id_to_country_lists(xml)]
    end

    private

    def tnt_id_to_country_lists(xml)
      Array.wrap(xml.tables['Country']['row']).map do |row|
        [row['id'], row['Description']]
      end
    end
  end
end
