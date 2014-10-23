require 'rexml/document'

class InsightController < ApplicationController

  def index
    @page_title = _('Insight')
    @current_user = current_user

    insight = Obiee.new
    session_id = insight.auth_client

    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             'mpdxRecurrDesig',
                             '0124650')
                             #Person::RelayAccount.where(person_id: current_user.id ).pluck('designation')[0])

    result_columns =  insight.report_results(session_id,sql)
    xmldoc = REXML::Document.new(result_columns)

    @col_headers = xmldoc.elements.to_a('//xsd:element').map { |el| el.attributes['saw-sql:columnHeading'].to_s}
    @col_values = xmldoc.elements[ '//Row' ].next_element.to_a

    @result_columns = result_columns
    end

end