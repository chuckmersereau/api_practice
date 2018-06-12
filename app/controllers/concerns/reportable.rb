module Reportable
  extend ActiveSupport::Concern

  def report_params
    report_params = { filter_params: filter_params.except(:account_list_id) }
    report_params[:account_list] = load_account_list if load_account_list
    report_params[:filter_params][:month_range] = filter_date_range
    report_params
  end

  def filter_date_range
    return nil if params.fetch(:filter, {})[:month_range].blank?
    ::Range.new(*params.fetch(:filter, {})[:month_range].split('...').map(&:to_date))
  end

  def load_account_list
    @account_list ||= account_lists.order(:created_at).first
  end

  def render_report
    render json: @report, fields: field_params, include: include_params
  end

  def permitted_filters
    [:account_list_id, :designation_account_id, :donor_account_id]
  end

  def authorize_report
    authorize(load_account_list, :show?)
  end
end
