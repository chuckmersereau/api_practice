class Tools::AnalyticsSerializer < ServiceSerializer
  attributes :counts_by_type

  delegate :counts_by_type,
           to: :object
end
