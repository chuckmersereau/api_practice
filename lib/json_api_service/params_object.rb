require 'active_support/hash_with_indifferent_access'
require 'json_api_service/object_store'
require 'json_api_service/data_object'

module JsonApiService
  class ParamsObject
    attr_reader :data,
                :data_params,
                :included_data,
                :included_params,
                :non_json_api_params,
                :params,
                :store

    def initialize(params:, store: ObjectStore.new)
      @data          = nil
      @included_data = []
      @params        = params.deep_symbolize_keys

      @data_params         = @params[:data] || {}
      @included_params     = @params[:included] || []
      @non_json_api_params = @params.except(:data, :included)
      @store               = store

      after_initialize
    end

    def to_h
      return {} if params.empty?

      {
        data: data.to_h
      }.merge(non_json_api_params)
    end

    private

    def after_initialize
      included_params.each do |included_data|
        DataObject.new(included_data, store: store)
      end

      @data = DataObject.new(data_params, store: store)
    end
  end
end
