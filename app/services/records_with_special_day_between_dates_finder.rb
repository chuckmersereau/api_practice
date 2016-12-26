class RecordsWithSpecialDayBetweenDatesFinder
  ATTRIBUTE_SELECTOR_TYPES = %i(day month).freeze

  attr_reader :attribute,
              :end_date,
              :scope,
              :start_date

  def initialize(attribute:, end_date:, scope:, start_date:)
    @attribute  = attribute
    @end_date   = end_date
    @scope      = scope
    @start_date = start_date

    after_initialize
  end

  ATTRIBUTE_SELECTOR_TYPES.each do |type|
    define_method "attribute_#{type}" do
      "#{attribute}_#{type}".to_sym
    end
  end

  def find
    scope.where(query_sql, query_arguments)
  end

  def query_arguments
    {
      start_year: start_date.year,
      end_year: end_date.year,
      start_date: start_date,
      end_date: end_date
    }
  end

  def query_sql
    same_year? ? same_year_sql : end_year_greater_sql
  end

  def same_year?
    start_date.year == end_date.year
  end

  def self.find(attribute:, end_date:, scope:, start_date:)
    new(
      attribute: attribute,
      end_date: end_date,
      scope: scope,
      start_date: start_date
    ).find
  end

  private

  def after_initialize
    if start_date > end_date
      raise ArgumentError, 'start_date cannot take place after end_date'
    end
  end

  def end_year_greater_sql
    <<~SQL
      (
        make_timestamptz(
          :start_year,
          #{attribute_month},
          #{attribute_day},
          0,
          0,
          0,
          '#{time_zone_identifier}'
        ) >= :start_date
      )
      OR
      (
        make_timestamptz(
          :end_year,
          #{attribute_month},
          #{attribute_day},
          0,
          0,
          0,
          '#{time_zone_identifier}'
        ) <= :end_date
      )
    SQL
  end

  def same_year_sql
    <<~SQL
      make_timestamptz(
        :start_year,
        #{attribute_month},
        #{attribute_day},
        0,
        0,
        0,
        '#{time_zone_identifier}'
      ) BETWEEN :start_date AND :end_date
    SQL
  end

  def time_zone_identifier
    @time_zone_identifier ||= Time.zone.tzinfo.identifier
  end
end
