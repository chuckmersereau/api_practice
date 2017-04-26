module Including
  UNPERMITTED_INCLUDE_PARAMS = ['**'].freeze

  private

  def include_params
    return [] unless params[:include]
    params[:include].split(',') - UNPERMITTED_INCLUDE_PARAMS
  end

  def include_associations(klass = nil)
    include_associations = ::JSONAPI::IncludeDirective.new(include_params - ['*']).to_hash
    return include_associations unless klass
    include_associations.select { |association| klass.reflections.include?(association) }
  end
end
