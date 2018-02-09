ActiveModelSerializers.config.key_transform = :underscore
ActiveModelSerializers.config.adapter = ActiveModelSerializers::Adapter::JsonApi
ActiveModelSerializers.config.jsonapi_pagination_links_enabled = false

class ActiveModelSerializers::Adapter::JsonApi
  Relationship.class_eval do
    def data_for(association)
      serializer = association.serializer

      if serializer.respond_to?(:each)
        serializer.map { |s| ResourceIdentifier.new(s, serializable_resource_options).as_json }
      elsif (virtual_value = association.options[:virtual_value])
        { id: virtual_value.id, type: virtual_value.class.to_s.underscore }.as_json
      elsif serializer && serializer.object
        ResourceIdentifier.new(serializer, serializable_resource_options).as_json
      end
    end
  end
end

module ActiveModelSerializers
  module Adapter
    class JsonApi
      class ResourceIdentifier
        private
        def id_for(serializer)
          serializer.read_attribute_for_serialization(:id).to_s
        end
      end
    end
  end
end
