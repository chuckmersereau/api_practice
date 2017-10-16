class Api::V2::Reports::MonthlyLossesGraphsController < Api::V2Controller
  def show
    load_report
    authorize_report
    render_report
  end

  protected

  def permit_coach?
    true
  end

  private

  def load_report
    @report ||= ::Reports::MonthlyLossesGraph.new(report_params)
  end

  def report_params
    {
      account_list: load_account_list,
      months: params[:months]&.to_i
    }
  end

  def load_account_list
    @account_list ||= AccountList.find_by(uuid: params[:id])
  end

  def render_report
    render json: @report, fields: field_params, include: include_params
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
