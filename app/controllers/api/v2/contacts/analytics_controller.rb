class Api::V2::Contacts::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def authorize_analytics
    authorize current_user, :show?
  end

  def contacts
    @contacts ||= current_user.contacts
  end

  def load_analytics
    @analytics ||= Contact::Analytics.new(contacts)
  end

  def render_analytics
    render json: @analytics,
           include: include_params,
           fields: field_params
  end
end
