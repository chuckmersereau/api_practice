class Api::V2::Reports::MonthlyGivingGraphsController < Api::V2Controller
  def show
    load_report
    authorize_report
    render_report
  end

  private

  def load_report
    @report ||= ::Reports::MonthlyGivingGraph.new(report_attributes)
  end

  def report_attributes
    load_account_list ? { account_list: load_account_list, locale: locale } : {}
  end

  def load_account_list
    @account_list ||= account_lists.first
  end

  def authorize_report
    authorize load_account_list, :show?
  end

  def render_report
    render json: @report, fields: field_params, include: include_params
  end

  def permitted_filters
    [:account_list_id]
  end
end