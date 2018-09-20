class Api::V2::Reports::WeekliesController < Api::V2Controller
  def index
    @sessions = Weekly.uniq.pluck(:session_id)
    render json: @sessions
  end

  def show
    load_report
    render json: @report
  end

  def create

  end

  def load_report
    @report = Weekly.find(params[:session_id])
  end

end
