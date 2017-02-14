require 'spec_helper'
require 'json_api_service/object_store'

module JsonApiService
  RSpec.describe ObjectStore do
    it 'initializes with empty items' do
      store = ObjectStore.new
      expect(store.items).to be_empty
    end
  end
end
