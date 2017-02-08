module JsonApiService
  class ResourceLookup
    attr_reader :custom_references

    def initialize(custom_references = {})
      @custom_references = custom_references
    end

    def find(resource_type)
      find_class(resource_type).constantize
    end

    private

    def find_class(resource_type)
      normalized_type = resource_type.to_s.pluralize

      custom_references[normalized_type.to_sym] || normalized_type.classify
    end
  end
end
