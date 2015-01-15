class InsightAnalyses


  def increase_recommendation_analysis( designation_number )
    insight = Obiee.new
    session_id = insight.auth_client({name: APP_CONFIG['obiee_key'], password: APP_CONFIG['obiee_secret'] })
    vars = { name: 'mpdxRecurrDesig',value: designation_number}
    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             vars)
   Hash.from_trusted_xml(insight.report_results(session_id,sql)).deep_symbolize_keys
  end

  def increase_recommendation_contacts(designation_number)

    recommends = increase_recommendation_analysis( designation_number)[:rowset][:Row]
    contacts_list = Array.new
    puts "say something"
puts recommends.inspect

    unless recommends.empty?
      recommends.each{ |c,val|
        puts "say hi"
        puts c.class
        if c.include?(:Column8)
          contacts_list.push(c[:Column8].to_s)
        end
      }
    end
    contacts_list
  end

end