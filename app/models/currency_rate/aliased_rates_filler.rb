class CurrencyRate
  class AliasedRatesFiller
    def fill_aliased_rates
      CurrencyAlias.all.find_each(&method(:fill_rates_for_alias))
    end

    private

    def fill_rates_for_alias(currency_alias)
      missing_dates(currency_alias).each do |missing_date|
        base_rate = CurrencyRate.find_by(code: currency_alias.rate_api_code,
                                         exchanged_on: missing_date).rate
        CurrencyRate.create(code: currency_alias.alias_code, source: 'alias',
                            rate: base_rate * currency_alias.ratio,
                            exchanged_on: missing_date)
      end
    end

    def missing_dates(currency_alias)
      CurrencyRate.connection.execute(missing_dates_sql(currency_alias))
                  .values.map(&:first)
    end

    def missing_dates_sql(currency_alias)
      quoted_alias_code = CurrencyRate.connection.quote(currency_alias.alias_code)
      quoted_rate_api_code = CurrencyRate.connection.quote(currency_alias.rate_api_code)
      <<-EOS
        SELECT primary_rates.exchanged_on
        FROM currency_rates primary_rates
        LEFT JOIN currency_rates aliased_rates
          ON aliased_rates.exchanged_on = primary_rates.exchanged_on
          AND aliased_rates.code = #{quoted_alias_code}
        WHERE primary_rates.code = #{quoted_rate_api_code}
        AND aliased_rates.id IS NULL
      EOS
    end
  end
end
