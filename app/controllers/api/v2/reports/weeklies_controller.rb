class Api::V2::Reports::WeekliesController < Api::V2Controller
  def show
    render json: @message
  end
end
