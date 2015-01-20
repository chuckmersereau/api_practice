class InsightAnalyses


  def increase_recommendation_analysis designation_number
    insight = Obiee.new
    vars = { name: 'mpdxRecurrDesig',value: designation_number}
    sql = insight.report_sql(insight.session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             vars)
  Hash.from_xml(insight.report_results(insight.session_id,sql))
  end

  def increase_recommendation_contacts designation_number

    recommends = increase_recommendation_analysis( designation_number)
    contacts_list = Array.new
    unless recommends.empty?
      recommends["rowset"]["Row"].each{ |c,val|
          contacts_list.push(c["Column8"])
      }
    end
    contacts_list
  end

  def partners_map_analysis designation_number
    insight = Obiee.new
    vars = { name: 'DesigVar',value: designation_number,name: 'StateVar', value: 'TX'}
    sql = insight.report_sql(insight.session_id,
                             '/shared/Insight/Census Temp/Staff Donation Geospatial',
                             vars)
    Hash.from_xml(insight.report_results(insight.session_id,sql))
  end

end