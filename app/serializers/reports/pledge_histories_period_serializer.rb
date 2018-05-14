class Reports::PledgeHistoriesPeriodSerializer < ServiceSerializer
  REPORT_ATTRIBUTES = [:start_date,
                       :end_date,
                       :pledged,
                       :received].freeze
  attributes(*REPORT_ATTRIBUTES)
  delegate(*REPORT_ATTRIBUTES, to: :object)

  def id
    start_date.strftime('%F')
  end
end
