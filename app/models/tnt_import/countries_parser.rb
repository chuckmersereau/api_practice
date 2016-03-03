class TntImport::CountriesParser
  class << self
    def countries_by_tnt_id(xml)
      return {} unless xml['Country'].present?
      Hash[tnt_id_to_country_lists(xml)]
    end

    private

    def tnt_id_to_country_lists(xml)
      Array.wrap(xml['Country']['row']).map do |row|
        [row['id'], row['Description']]
      end
    end
  end
end
