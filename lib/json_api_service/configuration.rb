require 'json_api_service/resource_lookup'

module JsonApiService
  class Configuration
    extend Forwardable

    attr_reader :ignored_foreign_keys,
                :resource_lookup

    def_delegator :resource_lookup, :custom_references

    def initialize
      @ignored_foreign_keys = Hash.new([])
      @resource_lookup      = ResourceLookup.new
    end

    def custom_references=(new_custom_references)
      @resource_lookup = ResourceLookup.new(new_custom_references)
    end

    def ignored_foreign_keys=(hash = {})
      @ignored_foreign_keys = Hash.new([]).merge!(hash)
    end
  end
end
