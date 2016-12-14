module Including
  UNPERMITTED_FILTER_PARAMS = ['**'].freeze

  private

  def include_params
    return [] unless params[:include]
    params[:include].split(',') - UNPERMITTED_FILTER_PARAMS
  end
end
