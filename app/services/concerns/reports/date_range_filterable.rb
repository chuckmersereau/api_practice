#
# DateRangeFilterable Concern expects to have the +filter_params+ be
# a +Hash+, that includes +month_range+ which is an instance of the
# +Range+ Object. The first argument of the range object is the starting date,
# the second argument of the range is the end date.
#
# e.g.
#
#   (Date.yesterday..Date.today)
#
module Concerns::Reports::DateRangeFilterable
  extend ActiveSupport::Concern

  MONTHS_BACK = 12

  def months
    (start_date..end_date).select { |date| date.day == 1 }
  end

  def start_date
    determine_start_date&.beginning_of_month || (end_date.beginning_of_month - MONTHS_BACK.months)
  end

  def end_date
    ending_on = filter_params&.fetch(:month_range, nil).try(:last)
    return ::Date.today if ending_on.blank?
    ending_on.to_date
  end

  def determine_start_date
    starting_on = filter_params&.fetch(:month_range, nil).try(:first)
    return nil if starting_on.blank?
    return nil if starting_on.to_date > end_date
    starting_on.to_date
  end
end
