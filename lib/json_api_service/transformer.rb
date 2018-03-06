require 'action_controller'
require 'json_api_service/params_object'

module JsonApiService
  class Transformer
    def self.transform(params:, configuration:)
      new(params: params, configuration: configuration).transform
    end

    attr_reader :configuration,
                :params

    def initialize(params:, configuration:)
      @orig_params     = params
      @params          = convert_params(params)
      @configuration   = configuration

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
      raise ArgumentError, argument_error_message unless @orig_params.is_a? ActionController::Parameters
    end

    def argument_error_message
      'must provide an ActionController::Parameters object, ie: the params from a controller action'
    end

    def attributes_for_object(object)
      (object.dig(:attributes) || {}).tap do |attributes|
        id = object.dig(:id)
        attributes[:id] = id if (create? || update?) && id.present? && id.to_sym != :undefined
      end
    end

    def convert_params(params_object)
      ParamsObject.new(params: params_object).to_h
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
      id          = value.dig(:data, :id)
      id = id == 'none' ? nil : id
      configuration.resource_lookup.find(value.dig(:data, :type)).find(id) if id
      { foreign_key => id }
    end

    def id_data_for_object(object, nested)
      id = object.dig(:id)
      return {} unless id && id.to_sym != :undefined
      return { id: id } if !nested || configuration.resource_lookup.find(object.dig(:type)).find_by(id: object.dig(:id))
      { _client_id: id }
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
        .map { |object| transform_data_object(object, true) }
    end

    def primary_key
      params.dig(:data, :type)&.singularize
    end

    def transform_data_object(object, nested = false)
      id_data           = id_data_for_object(object, nested)
      attributes        = attributes_for_object(object)
      foreign_keys      = foreign_keys_for_object(object)
      nested_attributes = nested_attributes_for_object(object)
      attributes.delete(:id) if nested && id_data.key?(:_client_id)
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
      transformed_object = filter_object.each_with_object({}) do |(foreign_key, id), hash|
        next unless foreign_key.to_s.end_with?('_id')
        id                = id.to_s.split(',').uniq.map(&:strip).select(&:presence)
        hash[foreign_key] = id.one? ? id.first : id
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
