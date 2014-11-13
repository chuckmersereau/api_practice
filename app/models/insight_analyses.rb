class InsightAnalyses


  def recommendations( designation_number )
    insight = Obiee.new
    session_id = insight.auth_client
    vars = { name: 'mpdxRecurrDesig',value: designation_number}
    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             vars)

   Hash.from_trusted_xml(insight.report_results(session_id,sql)).deep_symbolize_keys
  end

end