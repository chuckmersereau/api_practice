class Api::V2::Reports::WeekliesController < Api::V2Controller
  def index
    @sessions = Weekly.select('distinct on (session_id) *')
    render json: @sessions
  end

  def show
    load_report
    authorize(@report)
    render json: @report
  end

  def create
    @report = Weekly.new(params)
    @report.save
    authorize(@report)
    render jason: @report
  end

  def load_report
    @report = Weekly.where(:session_id => params[:session_id])
    #@report = @report.sort_by{|x| x.question_id}
  end

end
