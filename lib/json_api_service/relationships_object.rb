require 'forwardable'
require 'json_api_service/data_object'
require 'json_api_service/data_object_collection'
require 'json_api_service/null_data_object'

module JsonApiService
  class RelationshipsObject < BaseObject
    extend Forwardable

    def_delegators :relationships, :[]
    def_delegators :data, :empty?

    attr_reader :relationships

    def to_h
      relationships.each_with_object({}) do |(relationship_type, object), hash|
        hash[relationship_type] = {
          data: to_h_data_from_object(object)
        }
      end
    end

    def validate_against_store
      relationships.values.each(&:validate_against_store)
    end

    private

    def after_initialize
      parse_relationships
    end

    def parse_object_from_relationship_data(relationship_data, args)
      case relationship_data
      when Array
        DataObjectCollection.new(relationship_data, args)
      when Hash
        DataObject.new(relationship_data, args)
      else
        NullDataObject.new
      end
    end

    def parse_relationships
      @relationships = data.each_with_object({}) do |(relationship_type, hash_with_data), hash|
        relationship_data = hash_with_data.dig(:data)
        args              = { parent: self, store: store }
        parsed_object     = parse_object_from_relationship_data(relationship_data, args)

        hash[relationship_type] = parsed_object
      end
    end

    def to_h_data_from_object(object)
      case object
      when DataObject
        object.to_h
      when DataObjectCollection
        object.to_a
      end
    end
  end
end
