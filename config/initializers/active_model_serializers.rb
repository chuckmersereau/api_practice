ActiveModelSerializers.config.key_transform = :underscore

class ActiveModelSerializers::Adapter::JsonApi
  Relationship.class_eval do
    def data_for(association)
      serializer = association.serializer

      if serializer.respond_to?(:each)
        serializer.map { |s| ResourceIdentifier.new(s, serializable_resource_options).as_json }
      elsif (virtual_value = association.options[:virtual_value])
        { id: virtual_value.uuid, type: virtual_value.class.to_s.underscore }.as_json
      elsif serializer && serializer.object
        ResourceIdentifier.new(serializer, serializable_resource_options).as_json
      end
    end
  end
end
