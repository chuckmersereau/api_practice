module JsonApiService
  class ObjectStore
    attr_reader :items

    def initialize
      @items = {}
    end

    def [](type)
      items[type] || []
    end

    def add(data_object)
      id   = data_object.id
      type = data_object.type

      items[type] ||= {}
      items[type][id] ||= data_object

      self
    end

    def promote(item_to_promote)
      type = item_to_promote.type
      id   = item_to_promote.id

      return unless id && type

      items[type][id] = item_to_promote
    end
  end
end
