module JsonApiService
  class Validator
    def self.validate!(params:, context:, configuration:)
      new(
        params: params,
        context: context,
        configuration: configuration
      ).validate!
    end

    attr_reader :configuration,
                :context,
                :params

    def initialize(params:, configuration:, context:)
      @configuration = configuration
      @context       = context
      @params        = params
    end

    def validate!
      verify_resource_type!                         if create? || update? || (destroy? && data?)
      verify_type_existence!                        if create? || update? || (destroy? && data?)
      verify_absence_of_invalid_keys_in_attributes! if create? || update?

      true
    end

    def create?
      params.dig(:action).to_s.to_sym == :create
    end

    def update?
      params.dig(:action).to_s.to_sym == :update
    end

    def destroy?
      params.dig(:action).to_s.to_sym == :destroy
    end

    def data?
      !params.dig(:data).nil?
    end

    private

    def foreign_key_present_detail(reference_array)
      pointer_ref = "/#{reference_array.join('/')}"

      "Foreign keys SHOULD NOT be referenced in the #attributes of a JSONAPI resource object. Reference: #{pointer_ref}"
    end

    def foreign_key_present_error(reference_array)
      raise ForeignKeyPresentError, foreign_key_present_detail(reference_array)
    end

    def invalid_primary_key_placement_detail(reference_array)
      actual   = "/#{reference_array[0..-2].join('/')}/id"
      expected = "/#{reference_array[0..-3].join('/')}/id"

      [
        'A primary key, if sent in a request, CANNOT be referenced in the #attributes of a JSONAPI resource object.',
        "It must instead be sent as a top level member of the resource's `data` object. Reference: `#{actual}`. Expected `#{expected}`"
      ].join(' ')
    end

    def invalid_primary_key_placement_error(reference_array)
      raise InvalidPrimaryKeyPlacementError, invalid_primary_key_placement_detail(reference_array)
    end

    def ignored_foreign_keys
      configuration.ignored_foreign_keys
    end

    def invalid_resource_type_detail
      "'#{resource_type_from_params}' is not a valid resource type for this endpoint. Expected '#{context.resource_type}' instead"
    end

    def missing_resource_type_error(reference_array)
      raise MissingTypeError, missing_resource_type_detail(reference_array)
    end

    def missing_resource_type_detail(reference_array)
      pointer_ref = "/#{reference_array.join('/')}/type"

      "JSONAPI resource objects MUST contain a `type` top-level member of its hash for POST and PATCH requests. Expected to find a `type` member at #{pointer_ref}"
    end

    def resource_type_from_params?
      !resource_type_from_params.to_s.empty?
    end

    def resource_type_from_params
      params.dig(:data, :type)
    end

    def verify_resource_type!
      if (resource_type_from_params.to_s != context.resource_type.to_s) && resource_type_from_params?
        raise InvalidTypeError, invalid_resource_type_detail
      end
    end

    def verify_absence_of_invalid_keys_in_attributes!
      data_object      = params.dig(:data)
      includes_objects = params.dig(:included) || []

      verify_absence_of_invalid_key_attributes_in_data_object(data_object, [:data])
      verify_absence_of_invalid_key_attributes_in_objects_array(includes_objects, [:included])
    end

    def verify_absence_of_invalid_key_attributes_in_data_object(data_object, reference_array)
      resource_type = data_object.dig(:type)
      attributes    = data_object.dig(:attributes) || {}

      attributes.each do |attribute_key, _value|
        next if ignored_foreign_keys[resource_type.to_sym].include?(attribute_key.to_sym)

        new_reference_array = reference_array.dup << :attributes << attribute_key

        if attribute_key.end_with?('_id')
          foreign_key_present_error(new_reference_array)
        elsif attribute_key == 'id'
          invalid_primary_key_placement_error(new_reference_array)
        end
      end

      relationships = data_object.dig(:relationships) || {}
      verify_absence_of_invalid_key_attributes_in_relationships(relationships, reference_array)
    end

    def verify_absence_of_invalid_key_attributes_in_relationships(relationships, reference_array)
      reference_array << :relationships

      relationships.each do |reference, relationships_object|
        data_object = relationships_object.dig(:data)
        next unless data_object

        new_reference_array = reference_array.dup << reference << :data

        if data_object&.is_a? Array
          verify_absence_of_invalid_key_attributes_in_objects_array(data_object, new_reference_array)
        elsif data_object&.is_a? Hash
          verify_absence_of_invalid_key_attributes_in_data_object(data_object, new_reference_array)
        end
      end
    end

    def verify_absence_of_invalid_key_attributes_in_objects_array(objects_array, reference_array)
      objects_array.each_with_index do |object, index|
        new_reference_array = reference_array.dup << index

        verify_absence_of_invalid_key_attributes_in_data_object(object, new_reference_array)
      end
    end

    def verify_type_existence!
      data_object     = params.dig(:data) || {}
      includes_object = params.dig(:included) || []

      verify_type_existence_in_data_object(data_object, [:data])
      verify_type_existence_in_objects_array(includes_object, [:included])
    end

    def verify_type_existence_in_data_object(data_object, reference_array)
      missing_resource_type_error(reference_array) unless data_object.dig(:type)

      relationships = data_object.dig(:relationships) || {}
      verify_type_existince_in_relationships(relationships, reference_array.dup)
    end

    def verify_type_existence_in_objects_array(objects_array, reference_array)
      objects_array.each_with_index do |object, index|
        new_reference_array = reference_array.dup << index

        verify_type_existence_in_data_object(object, new_reference_array)
      end
    end

    def verify_type_existince_in_relationships(relationships, reference_array)
      reference_array << :relationships

      relationships.each do |reference, relationships_object|
        data_object = relationships_object.dig(:data)
        next unless data_object

        new_reference_array = reference_array.dup << reference << :data

        if data_object&.is_a? Array
          verify_type_existence_in_objects_array(data_object, new_reference_array)
        elsif data_object&.is_a? Hash
          verify_type_existence_in_data_object(data_object, new_reference_array)
        end
      end
    end
  end
end
