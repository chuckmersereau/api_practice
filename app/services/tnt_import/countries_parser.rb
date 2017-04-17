class TntImport::CountriesParser
  class << self
    def countries_by_tnt_id(xml)
      Hash[tnt_id_to_country_lists(xml).to_a]
    end

    private

    def tnt_id_to_country_lists(xml)
      xml.tables['Country'].map do |row|
        [row['id'], row['Description']]
      end
    end
  end
end
