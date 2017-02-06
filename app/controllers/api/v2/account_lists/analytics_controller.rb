class Api::V2::AccountLists::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def authorize_analytics
    authorize(load_account_list, :show?)
  end

  def analytics_scope
    current_user.account_lists
  end

  def load_analytics
    @analytics ||= AccountList::Analytics.new(analytics_params)
  end

  def load_account_list
    @account_list ||= analytics_scope.find_by!(uuid: params[:account_list_id])
  end

  def analytics_params
    {
      start_date: 1.month.ago,
      end_date: Time.current
    }.merge(filter_params)
      .merge(account_list: load_account_list)
  end

  def permitted_filters
    [:start_date, :end_date]
  end

  def render_analytics
    render json: @analytics, fields: field_params, include: include_params
  end
end
