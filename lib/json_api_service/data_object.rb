require 'json_api_service/base_object'
require 'json_api_service/relationships_object'

module JsonApiService
  class DataObject < BaseObject
    attr_reader :relationships

    def attributes
      @attributes ||= data.dig(:attributes) || {}
    end

    def id
      data.dig(:id)
    end

    def merge(alternate)
      @attributes    = alternate.attributes if attributes.empty?
      @relationships = alternate.relationships if relationships.empty?

      self
    end

    def to_h
      validate_against_store

      {}.tap do |hash|
        hash[:id] = id if id
        hash[:type] = type
        hash[:attributes] = attributes unless attributes.empty?
        hash[:relationships] = relationships.to_h unless relationships.empty?
      end
    end

    def type
      data.dig(:type)
    end

    def validate_against_store
      return unless id && !id.empty?

      version_from_store = store[type][id]
      merge(version_from_store)

      relationships.validate_against_store
      store.promote(self)
    end

    private

    def after_initialize
      parse_relationships

      store.add(self)
    end

    def parse_relationships
      relationships = data.dig(:relationships)
      args          = { parent: self, store: store }

      @relationships = RelationshipsObject.new(relationships, args)
    end
  end
end
