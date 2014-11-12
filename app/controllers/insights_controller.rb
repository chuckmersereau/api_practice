class InsightsController < ApplicationController

  def index
    @page_title = _('Insights')
    @current_user = current_user

    insight = Obiee.new
    session_id = insight.auth_client
    vars = { name: 'mpdxRecurrDesig',value: current_account_list.designation_accounts.pluck(:designation_number).first }
    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                            vars)

    xsd_results =  insight.report_results(session_id,sql)
    dom = Hash.from_trusted_xml(xsd_results).deep_symbolize_keys

    @xsd_results = dom[:rowset][:Row]
    @acct = current_account_list

  end

end