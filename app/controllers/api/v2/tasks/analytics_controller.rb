class Api::V2::Tasks::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def authorize_analytics
    account_lists.each { |account_list| authorize account_list, :show? }
  end

  def load_analytics
    @analytics ||= Task::Analytics.new(load_tasks)
  end

  def load_tasks
    Task.where(account_list_id: account_lists.map(&:id))
  end

  def permitted_filters
    [:account_list_id]
  end

  def render_analytics
    render json: @analytics,
           include: include_params,
           fields: field_params,
           serializer: Task::AnalyticsSerializer
  end
end
