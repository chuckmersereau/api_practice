module Including
  UNPERMITTED_INCLUDE_PARAMS = ['**'].freeze

  private

  def include_params
    return [] unless params[:include]

    if requested_include_params_that_are_permitted.include?('*')
      fetch_full_list_of_include_params
    else
      requested_include_params_that_are_permitted
    end
  end

  def requested_include_params_that_are_permitted
    @requested_include_params_that_are_permitted ||= params[:include].split(',').map(&:strip) - UNPERMITTED_INCLUDE_PARAMS
  end

  def fetch_full_list_of_include_params
    (full_list_of_direct_associations + requested_include_params_that_are_permitted - ['*']).uniq.map(&:to_s)
  end

  def full_list_of_direct_associations
    serializer_class._reflections.keys
  end

  def serializer_class
    (CONTROLLER_TO_SERIALIZER_LOOKUP[self.class.to_s] || "#{resource_class_name}Serializer").constantize
  end

  def resource_class_name
    normalized_type = resource_type.to_s.pluralize

    JsonApiService.configuration.custom_references[normalized_type.to_sym] || normalized_type.classify
  end

  def include_associations
    ::JSONAPI::IncludeDirective.new(include_params - ['*']).to_hash
  end
end
