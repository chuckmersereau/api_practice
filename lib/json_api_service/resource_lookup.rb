module JsonApiService
  class ResourceLookup
    attr_reader :custom_references

    def initialize(custom_references = {})
      @custom_references = custom_references
    end

    def find(resource_type)
      find_class_by_type(resource_type).constantize
    end

    def find_type_by_class(resource_class)
      resource_class_name = resource_class.to_s
      return nil if resource_class_name.blank?
      custom_references.detect { |_, class_name| class_name == resource_class_name }&.first ||
        resource_class_name.underscore.pluralize.to_sym
    end

    private

    def find_class_by_type(resource_type)
      normalized_type = resource_type.to_s.pluralize

      custom_references[normalized_type.to_sym] || normalized_type.classify
    end
  end
end
