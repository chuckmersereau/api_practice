module BetweenScopeable
  extend ActiveSupport::Concern

  module ClassMethods
    def between_scope_for(attribute)
      singleton_class.instance_eval do
        define_method "with_#{attribute}_between" do |start_date, end_date|
          query_arguments = between_finder_query_arguments(start_date, end_date)
          query_sql = between_finder_query_sql(attribute, start_date, end_date)

          where(query_sql, query_arguments)
        end
      end
    end

    private

    def between_finder_end_year_greater_sql(attribute)
      <<~SQL
        (
          make_timestamptz(
            :start_year,
            #{attribute}_month,
            #{attribute}_day,
            0,
            0,
            0,
            '#{between_finder_time_zone_identifier}'
          ) >= :start_date
        )
        OR
        (
          make_timestamptz(
            :end_year,
            #{attribute}_month,
            #{attribute}_day,
            0,
            0,
            0,
            '#{between_finder_time_zone_identifier}'
          ) <= :end_date
        )
      SQL
    end

    def between_finder_query_arguments(start_date, end_date)
      {
        start_year: start_date.year,
        end_year: end_date.year,
        start_date: start_date,
        end_date: end_date
      }
    end

    def between_finder_query_sql(attribute, start_date, end_date)
      if start_date.year == end_date.year
        between_finder_same_year_sql(attribute)
      elsif start_date.year < end_date.year
        between_finder_end_year_greater_sql(attribute)
      else
        raise ArgumentError, 'start_date cannot take place after end_date'
      end
    end

    def between_finder_same_year_sql(attribute)
      <<~SQL
        make_timestamptz(
          :start_year,
          #{attribute}_month,
          #{attribute}_day,
          0,
          0,
          0,
          '#{between_finder_time_zone_identifier}'
        ) BETWEEN :start_date AND :end_date
      SQL
    end

    def between_finder_time_zone_identifier
      Time.zone.tzinfo.identifier
    end
  end
end
