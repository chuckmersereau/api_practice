class Api::V2::Reports::AppointmentResultsController < Api::V2Controller
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

  def coach?
    !load_account_list.users.where(id: current_user).exists? &&
      load_account_list.coaches.where(id: current_user).exists?
  end

  def load_report
    @report ||= ::Reports::AppointmentResults.new(report_params)
  end

  def report_params
    { account_list: load_account_list }.merge(filter_params.except(:account_list_id))
  end

  def load_account_list
    @account_list ||= account_lists.order(:created_at).first
  end

  def render_report
    options = {
      json: @report.periods_data,
      fields: field_params,
      include: include_params,
      meta: meta_hash
    }
    options[:each_serializer] = Coaching::Reports::AppointmentResultsPeriodSerializer if coach?
    render options
  end

  def meta_hash
    {
      sort: sorting_param_applied_to_query,
      filter: permitted_filter_params_with_ids,
      averages: @report.meta(field_params)
    }
  end

  def permitted_filters
    [:account_list_id, :period, :end_date]
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
