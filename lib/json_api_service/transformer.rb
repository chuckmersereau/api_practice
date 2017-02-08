require 'action_controller'
require 'json_api_service/uuid_to_id_reference_fetcher'

module JsonApiService
  class Transformer
    def self.transform(params:, configuration:)
      new(params: params, configuration: configuration).transform
    end

    attr_reader :configuration,
                :params,
                :uuid_references

    def initialize(params:, configuration:)
      @params          = params
      @configuration   = configuration
      @uuid_references = UuidToIdReferenceFetcher.new(
        params: params,
        configuration: configuration
      )

      after_initialize
    end

    def create?
      params.dig(:action).to_s.to_sym == :create
    end

    def update?
      params.dig(:action).to_s.to_sym == :update
    end

    def transform
      ActionController::Parameters.new(transform_params)
    end

    private

    def after_initialize
      unless params.is_a? ActionController::Parameters
        raise ArgumentError, argument_error_message
      end
    end

    def argument_error_message
      'must provide an ActionController::Parameters object, ie: the params from a controller action'
    end

    def attributes_for_object(object)
      (object.dig(:attributes) || {}).tap do |attributes|
        uuid = object.dig(:id)

        attributes[:uuid] = uuid if (create? || update?) && uuid.present?
      end
    end

    def foreign_keys_for_object(object)
      relationships = object.dig(:relationships) || {}

      relationships
        .select { |_type, value| value.dig(:data).is_a? Hash }
        .each_with_object({}) do |(key, value), hash|
          foreign_key = "#{key}_id"
          uuid        = value.dig(:data, :id)
          type        = value.dig(:data, :type)
          id          = uuid_references[type][uuid]

          hash[foreign_key] = id
        end
    end

    def id_data_for_object(object)
      uuid = object.dig(:id)

      if update? && uuid
        type = object.dig(:type)
        id   = uuid_references[type][uuid]

        { id: id }
      else
        {}
      end
    end

    def nested_attributes_for_object(object)
      relationships = object.dig(:relationships) || {}

      relationships
        .select { |_type, value| value.dig(:data).is_a? Array }
        .each_with_object({}) do |(type, value), hash|
          id_key  = "#{type}_attributes"
          objects = value.dig(:data)

          hash[id_key] = objects_array_to_nested_attributes_hash(objects)
        end
    end

    def objects_array_to_nested_attributes_hash(objects)
      objects
        .each_with_object({})
        .with_index do |(object, hash), index|
          hash[index] = transform_data_object(object)
        end
    end

    def primary_key
      params.dig(:data, :type)&.singularize
    end

    def transform_data_object(object)
      id_data           = id_data_for_object(object)
      attributes        = attributes_for_object(object)
      foreign_keys      = foreign_keys_for_object(object)
      nested_attributes = nested_attributes_for_object(object)

      attributes
        .merge!(id_data)
        .merge!(foreign_keys)
        .merge!(nested_attributes)
    end

    def transformed_non_data_params
      non_data_params = params.except(:data)
      filter_object   = params.dig(:filter)

      non_data_params.tap do |params|
        params[:filter] = transform_filter_object(filter_object) if filter_object
      end
    end

    def transform_filter_object(filter_object)
      transformed_object = filter_object.each_with_object({}) do |(foreign_key, uuid), hash|
        next unless foreign_key.end_with?('_id')

        resource_type = foreign_key.sub('_id', '').pluralize
        id            = uuid_references[resource_type][uuid]

        hash[foreign_key] = id
      end

      filter_object.merge!(transformed_object)
    end

    def transform_params
      if create? || update?
        {
          primary_key => transform_data_object(params.dig(:data))
        }.merge!(transformed_non_data_params)
      else
        transformed_non_data_params
      end
    end
  end
end
