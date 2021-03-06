class Api::V2::Reports::YearDonationsController < Api::V2Controller
  def show
    load_report
    authorize_report
    render_report
  end

  private

  def load_report
    @report ||= ::Reports::YearDonations.new(report_params)
  end

  def report_params
    load_account_list ? { account_list: load_account_list } : {}
  end

  def load_account_list
    @account_list ||= account_lists.order(:created_at).first
  end

  def render_report
    render json: @report, fields: field_params, include: include_params
  end

  def permitted_filters
    [:account_list_id]
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
