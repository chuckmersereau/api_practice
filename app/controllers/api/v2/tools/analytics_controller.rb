class Api::V2::Tools::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def authorize_analytics
    account_lists.each do |account_list|
      authorize account_list, :show?
    end
  end

  def load_analytics
    @analytics ||= ::Tools::Analytics.new(analytics_params)
  end

  def analytics_params
    { account_lists: account_lists }
  end

  def permitted_filters
    [:account_list_id]
  end

  def render_analytics
    render json: @analytics, fields: field_params, include: include_params
  end
end
