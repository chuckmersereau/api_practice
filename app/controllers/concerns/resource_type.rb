module ResourceType
  extend ActiveSupport::Concern

  def resource_type
    self.class.custom_resource_type || resource_type_from_class_name
  end

  private

  def invalid_resource_type_detail
    if resource_type_from_params.to_s.empty?
      "MUST supply a resource type for POST and PATCH requests. Expected type for this endpoint is '#{resource_type}'"
    else
      "'#{resource_type_from_params}' is not a valid resource type for this endpoint. Expected '#{resource_type}' instead"
    end
  end

  def resource_type_from_class_name
    self.class
        .name
        .split('::')
        .last
        .underscore
        .sub('_controller', '')
        .to_sym
  end

  def resource_type_from_params
    params.dig(:data, :type).to_s.to_sym
  end

  def verify_resource_type
    return if resource_type_from_params == resource_type

    render_409(detail: invalid_resource_type_detail)
  end

  module ClassMethods
    def custom_resource_type
      @resource_type&.to_sym
    end

    def resource_type(type)
      @resource_type = type
    end
  end
end
