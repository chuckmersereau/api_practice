class Api::V2::Reports::DonationMonthlyTotalsController < Api::V2Controller
  def show
    load_report
    authorize_report
    render_report
  end

  private

  def load_report
    @report ||= ::Reports::DonationMonthlyTotals.new(report_params)
  end

  def report_params
    {
      account_list: load_account_list,
      start_date: filter_params[:month_range].first,
      end_date: filter_params[:month_range].last
    }
  end

  def load_account_list
    @account_list ||= account_lists.first
  end

  def render_report
    render json: @report
  end

  def permitted_filters
    [:account_list_id, :month_range]
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
