module BetweenScopeable
  extend ActiveSupport::Concern

  module ClassMethods
    def between_scopes_for(attribute)
      singleton_class.instance_eval do
        define_method "with_#{attribute}_this_week" do |start_date = Date.current.beginning_of_week|
          end_date = start_date + 6.days

          if start_date.month == end_date.month
            send("with_#{attribute}_in_same_month_between_two_dates", start_date, end_date)
          else
            send("with_#{attribute}_in_neighboring_months_between_two_dates", start_date, end_date)
          end
        end

        define_method "with_#{attribute}_in_same_month_between_two_dates" do |start_date, end_date|
          between_scopeable_validate_date_order(start_date, end_date)
          between_scopeable_validate_same_month(start_date, end_date)

          sql = between_scopeable_same_month_sql(attribute)
          query_arguments = {
            month: start_date.month,
            start_day: start_date.day,
            end_day: end_date.day
          }

          where(sql, query_arguments)
        end

        define_method "with_#{attribute}_in_neighboring_months_between_two_dates" do |start_date, end_date|
          between_scopeable_validate_date_order(start_date, end_date)
          between_scopeable_validate_neighboring_months(start_date, end_date)

          sql = between_scopeable_neighboring_months_sql(attribute)
          query_arguments = {
            start_day: start_date.day,
            start_month: start_date.month,
            end_day: end_date.day,
            end_month: end_date.month
          }

          where(sql, query_arguments)
        end
      end
    end

    private

    def between_scopeable_neighboring_months_sql(attribute)
      <<~SQL
        (
          #{attribute}_month = :start_month AND #{attribute}_day >= :start_day
        ) OR (
          #{attribute}_month = :end_month AND #{attribute}_day <= :end_day
        )
      SQL
    end

    def between_scopeable_same_month_sql(attribute)
      <<~SQL
        #{attribute}_month = :month
        AND
        #{attribute}_day BETWEEN :start_day AND :end_day
      SQL
    end

    def between_scopeable_validate_date_order(start_date, end_date)
      raise ArgumentError, 'start_date cannot take place after end_date' if start_date > end_date
    end

    def between_scopeable_validate_neighboring_months(start_date, end_date)
      return if start_date.month == 12 && end_date.month == 1
      return if (end_date.month > start_date.month) && (end_date.month - start_date.month <= 1)

      raise ArgumentError, 'dates cannot be more than one month apart'
    end

    def between_scopeable_validate_same_month(start_date, end_date)
      raise ArgumentError, 'dates must be in the same month' if start_date.month != end_date.month
    end
  end
end
