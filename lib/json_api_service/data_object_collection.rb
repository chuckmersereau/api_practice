require 'json_api_service/base_object'

module JsonApiService
  class DataObjectCollection < BaseObject
    include Enumerable

    attr_reader :items

    def to_a
      items.map(&:to_h)
    end

    def each
      items.each { |item| yield(item) }
    end

    def validate_against_store
      each(&:validate_against_store)
    end

    private

    def after_initialize
      parse_items
    end

    def parse_items
      @items = data.map do |item_data|
        DataObject.new(item_data, parent: self, store: store)
      end
    end
  end
end
