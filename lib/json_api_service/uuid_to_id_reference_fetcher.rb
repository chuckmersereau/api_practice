require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'active_record'

require_relative '../../config/initializers/regex_constants'

module JsonApiService
  class UuidToIdReferenceFetcher
    attr_reader :params,
                :configuration

    def initialize(params:, configuration:)
      @params        = params
      @configuration = configuration
      @references    = HashWithIndifferentAccess.new({})
    end

    def [](key)
      references[key] ||= fetch_references_for(key)
    end

    def fetch
      uuids.keys.each { |key| send(:[], key) }

      references
    end

    def uuids
      @uuids ||= find_and_assign_uuids
    end

    private

    attr_reader :references

    def fetch_references_for(resource_type)
      resource_class  = resource_lookup.find(resource_type)
      found_uuids     = uuids[resource_type]

      raise_record_not_found(resource_type, found_uuids) if found_uuids.any? { |uuid| !::UUID_REGEX.match(uuid) }

      found_resources = resource_class.where(uuid: found_uuids).pluck(:id, :uuid)

      found_resources.each_with_object({}) do |(id, uuid), hash|
        hash[uuid] = id
      end
    end

    def raise_record_not_found(resource_type, uuids)
      message = statement_invalid_error_message(resource_type.to_s.singularize, uuids)

      raise ActiveRecord::RecordNotFound, message
    end

    def statement_invalid_error_message(key, uuids)
      if uuids.count > 1
        "The resources '#{key}' with ids '#{uuids.join(', ')}' do not exist"
      else
        "Resource '#{key}' with id '#{uuids.first}' does not exist"
      end
    end

    def find_and_assign_uuids
      uuids         = HashWithIndifferentAccess.new({})
      data_object   = params.dig(:data)
      filter_object = params.dig(:filter)

      pull_uuids_from_data_object(data_object, uuids) if data_object
      pull_uuids_from_filter_object(filter_object, uuids) if filter_object

      uuids
    end

    def pull_uuids_from_data_object(object, uuids)
      return unless object

      resource_type = object.fetch(:type)
      uuid          = object.dig(:id)

      if uuid
        uuids[resource_type] ||= []
        uuids[resource_type] << uuid
      end

      relationships = object.dig(:relationships) || {}
      pull_uuids_from_relationships(relationships, uuids)

      uuids
    end

    def pull_uuids_from_filter_object(filter_object, uuids)
      filter_object.each do |key, value|
        next unless key.to_s.end_with?('_id')

        resource_type = key.to_s.sub('_id', '').pluralize
        uuids[resource_type] ||= []
        uuids[resource_type] += value.to_s.split(',').uniq.map(&:strip).select(&:presence)
        uuids[resource_type].uniq!
      end

      uuids
    end

    def pull_uuids_from_data_objects_array(objects_array, uuids)
      objects_array.each do |data_object|
        pull_uuids_from_data_object(data_object, uuids) if data_object
      end
    end

    def pull_uuids_from_relationships(relationships, uuids)
      relationships.each do |_reference, relationships_object|
        data_object = relationships_object.dig(:data)
        next unless data_object

        if data_object.is_a? Array
          pull_uuids_from_data_objects_array(data_object, uuids)
        else
          pull_uuids_from_data_object(data_object, uuids)
        end
      end
    end

    def resource_lookup
      @resource_lookup ||= configuration.resource_lookup
    end
  end
end
