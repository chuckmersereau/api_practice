class Api::V2::Reports::MonthlyGivingGraphsController < Api::V2Controller
  def show
    load_report
    authorize_report
    render_report
  end

  private

  def authorize_report
    authorize load_account_list, :show?
  end

  def load_account_list
    @account_list ||= account_lists.first
  end

  def load_report
    @report ||= ::Reports::MonthlyGivingGraph.new(report_attributes)
  end

  def permitted_filters
    [
      :account_list_id,
      :donation_date,
      :donor_account_id
    ]
  end

  def report_attributes
    {
      account_list: load_account_list,
      filter_params: filter_params,
      locale: locale
    }
  end

  def render_report
    render json: @report,
           fields: field_params,
           include: include_params
  end
end
