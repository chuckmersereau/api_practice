class Api::V2::Constants::ActivitiesController < Api::V2Controller
  def index
    load_activities
    render_activities
  end

  private

  def load_activities
    @activities ||= ::Constants::ActivityList.new
  end

  def render_activities
    render json: @activities
  end

  def permitted_filters
    []
  end
end
