class InsightAnalyses
  def increase_recommendation_analysis(designation_number)
    insight = Obiee.new
    vars = { name: 'mpdxRecurrDesig', value: designation_number }
    returned_xml = insight.report_results(insight.session_id,
                                          '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                                          vars)
    Hash.from_xml(returned_xml)
  end

  def increase_recommendation_contacts(designation_number)
    recommends = increase_recommendation_analysis(designation_number)
    contacts_list = []
    if recommends && recommends['rowset']['Row']
      recommends['rowset']['Row'].each do |c, _val|
        contacts_list.push(c['Column0'])
      end
    end
    contacts_list
  end
end
