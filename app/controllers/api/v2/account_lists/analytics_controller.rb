class Api::V2::AccountLists::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  protected

  def permit_coach?
    true
  end

  private

  def authorize_analytics
    authorize(load_account_list, :show?)
  end

  def load_analytics
    @analytics ||= AccountList::Analytics.new(analytics_params)
  end

  def load_account_list
    @account_list ||= account_lists.find(params[:account_list_id])
  end

  def analytics_params
    {
      start_date: (filter_params[:date_range].try(:first) || 1.month.ago),
      end_date: (filter_params[:date_range].try(:last) || Time.current)
    }.merge(account_list: load_account_list)
  end

  def permitted_filters
    [:date_range]
  end

  def render_analytics
    render json: @analytics, fields: field_params, include: include_params
  end
end
