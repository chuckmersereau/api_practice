require 'action_controller'
require 'json_api_service/uuid_to_id_reference_fetcher'
require 'json_api_service/params_object'

module JsonApiService
  class Transformer
    def self.transform(params:, configuration:)
      new(params: params, configuration: configuration).transform
    end

    attr_reader :configuration,
                :params,
                :uuid_references

    def initialize(params:, configuration:)
      @orig_params     = params
      @params          = convert_params(params)
      @configuration   = configuration
      @uuid_references = UuidToIdReferenceFetcher.new(
        params: @params.dup,
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

    def destroy?
      params.dig(:action).to_s.to_sym == :destroy
    end

    def transform
      ActionController::Parameters.new(transform_params)
    end

    private

    def after_initialize
      unless @orig_params.is_a? ActionController::Parameters
        raise ArgumentError, argument_error_message
      end
    end

    def argument_error_message
      'must provide an ActionController::Parameters object, ie: the params from a controller action'
    end

    def attributes_for_object(object)
      (object.dig(:attributes) || {}).tap do |attributes|
        uuid = object.dig(:id)

        if (create? || update?) && uuid.present? && uuid.to_sym != :undefined
          attributes[:uuid] = uuid
        end
      end
    end

    def convert_params(params_object)
      ParamsObject.new(params: params_object).to_h
    end

    def fetch_id_from_resource_type_and_uuid(resource_type, uuid)
      id = uuid.to_s
               .split(',')
               .uniq
               .map(&:strip)
               .select(&:presence)
               .map { |single_uuid| uuid_references[resource_type][single_uuid] }

      if id.one?
        id.first
      else
        id
      end
    end

    def foreign_keys_for_object(object)
      relationships = object.dig(:relationships) || {}

      relationships
        .select { |_type, value| value.dig(:data).is_a? Hash }
        .each_with_object({}) do |(key, value), hash|
          hash.merge!(generate_foreign_key_from_relationship(key, value))
        end
    end

    def generate_foreign_key_from_relationship(key, value)
      foreign_key = "#{key}_id"
      uuid        = value.dig(:data, :id)
      type        = value.dig(:data, :type)

      id = if uuid == 'none'
             nil
           else
             uuid_references[type][uuid]
           end

      { foreign_key => id }
    end

    def id_data_for_object(object)
      uuid = object.dig(:id)
      return {} unless uuid && uuid.to_sym != :undefined

      type = object.dig(:type)
      id   = uuid_references[type][uuid]

      id ? { id: id } : {}
    end

    def nested_attributes_for_object(object)
      relationships = object.dig(:relationships) || {}

      relationships
        .select { |_type, value| value.dig(:data).is_a? Array }
        .each_with_object({}) do |(type, value), hash|
          id_key  = "#{type}_attributes"
          objects = value.dig(:data)

          hash[id_key] = objects_array_to_nested_attributes_hash(objects).map do |attribute_hash|
            attribute_hash.merge(overwrite: true)
          end
        end
    end

    def objects_array_to_nested_attributes_hash(objects)
      objects
        .each_with_object({})
        .map { |object| transform_data_object(object) }
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
        next unless foreign_key.to_s.end_with?('_id')

        resource_type = foreign_key.to_s.sub('_id', '').pluralize
        id            = fetch_id_from_resource_type_and_uuid(resource_type, uuid)

        hash[foreign_key] = id
      end

      filter_object.merge!(transformed_object)
    end

    def transform_params
      if create? || update? || destroy?
        {
          primary_key => transform_data_object(params.dig(:data))
        }.merge!(transformed_non_data_params)
      else
        transformed_non_data_params
      end
    end
  end
end
