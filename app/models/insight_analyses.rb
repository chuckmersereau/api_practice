class InsightAnalyses
  def increase_recommendation_analysis(designation_number)
    insight = Obiee.new
    vars = { name: 'mpdxRecurrDesig', value: designation_number }
    sql = insight.report_sql(insight.session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             vars)
    Hash.from_xml(insight.report_results(insight.session_id, sql))
  end

  def increase_recommendation_contacts(designation_number)
    recommends = increase_recommendation_analysis(designation_number)
    contacts_list = []
    if recommends && recommends['rowset']['Row']
      recommends['rowset']['Row'].each do |c, _val|
        contacts_list.push(c['Column8'])
      end
    end
    contacts_list
  end
end
