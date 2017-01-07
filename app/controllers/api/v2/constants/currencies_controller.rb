class Api::V2::Constants::CurrenciesController < Api::V2Controller
  def index
    load_currencies
    render_currencies
  end

  private

  def load_currencies
    @currencies ||= ::Constants::CurrencyList.new
  end

  def render_currencies
    render json: @currencies
  end

  def permitted_filters
    []
  end
end
