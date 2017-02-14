module JsonApiService
  class BaseObject
    attr_reader :data,
                :parent,
                :store

    def initialize(data, parent: nil, store:)
      @data   = data || {}
      @parent = parent
      @store  = store

      after_initialize
    end

    def parent?
      parent
    end

    private

    def after_initialize; end
  end
end
