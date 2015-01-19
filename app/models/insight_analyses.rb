class InsightAnalyses


  def increase_recommendation_analysis( designation_number )
    insight = Obiee.new
    session_id = insight.auth_client({name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] })
    vars = { name: 'mpdxRecurrDesig',value: designation_number}
    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             vars)
  Hash.from_xml(insight.report_results(session_id,sql))
  end

  def increase_recommendation_contacts(designation_number)

    recommends = increase_recommendation_analysis( designation_number)
    contacts_list = Array.new
    unless recommends.empty?
      recommends["rowset"]["Row"].each{ |c,val|
          contacts_list.push(c["Column8"])
      }
    end
    contacts_list
  end

end