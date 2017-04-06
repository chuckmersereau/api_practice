module Including
  UNPERMITTED_INCLUDE_PARAMS = ['**'].freeze

  private

  def include_params
    return [] unless params[:include]
    params[:include].split(',') - UNPERMITTED_INCLUDE_PARAMS
  end

  def include_associations
    ::JSONAPI::IncludeDirective.new(include_params - ['*']).to_hash
  end
end
