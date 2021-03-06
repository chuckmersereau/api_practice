class Api::V2::Reports::PledgeHistoriesController < Api::V2Controller
  include Filtering

  def index
    load_report
    authorize_report
    render_report
  end

  private

  def permit_coach?
    true
  end

  def load_report
    @report ||= ::Reports::PledgeHistories.new(report_params)
  end

  def report_params
    { account_list: load_account_list }.merge(filter_params.except(:account_list_id))
  end

  def load_account_list
    @account_list ||= account_lists.order(:created_at).first
  end

  def render_report
    render json: @report.periods_data,
           fields: field_params,
           include: include_params,
           meta: meta_hash
  end

  def meta_hash
    {
      filter: permitted_filter_params_with_ids
    }
  end

  def permitted_filters
    [:account_list_id, :period, :end_date]
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
