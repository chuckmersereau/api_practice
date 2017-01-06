class Api::V2::Constants::LocalesController < Api::V2Controller
  def index
    load_locales
    render_locales
  end

  private

  def load_locales
    @locales ||= ::Constants::LocaleList.new
  end

  def render_locales
    render json: @locales
  end

  def permitted_filters
    []
  end
end
