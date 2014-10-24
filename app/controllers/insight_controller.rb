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
                             Person::RelayAccount.where(person_id: current_user.id ).pluck('designation')[0])

    xsd_results =  insight.report_results(session_id,sql)

    dom = Hash.from_trusted_xml(xsd_results).deep_symbolize_keys

    @xsd_results = dom[:rowset][:Row]
    end

end