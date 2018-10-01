class Api::V2::Reports::SessionsController < Api::V2Controller
  def show
    @sessions = Session.where(:user => params[:id])
    authorize(@sessions)
    render json: @sessions
  end

  def create
    @session = Session.new(session_params)
    @session.save
    authorize(@session)
    render json: @session
  end

  private
  def session_params
    params.require(:session).permit(:user, :sid)
  end
end
