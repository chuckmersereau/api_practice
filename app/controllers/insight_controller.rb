
class InsightController < ApplicationController

  def index
    @page_title = _('Insight')
    @current_user = current_user

    insight = ObieeWsdl.new
    session_id = insight.auth_client

    sql = insight.report_sql(session_id,
                             '/shared/Insight/Siebel Recurring Monthly/Recurring Gift Recommendations',
                             'mpdxRecurrDesig',
                             Person::RelayAccount.where(person_id: current_user.id ).pluck('designation')[0])

    result_columns =  insight.report_results(session_id,sql)

    @desig_accnt = result_columns

    end

end