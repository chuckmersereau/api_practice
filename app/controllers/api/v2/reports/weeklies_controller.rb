class Api::V2::Reports::WeekliesController < Api::V2Controller
  def index
    render json: @message
  end
end
