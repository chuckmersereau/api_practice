require 'spec_helper'
require 'json_api_service/object_store'
require 'json_api_service/relationships_object'

module JsonApiService
  RSpec.describe RelationshipsObject do
    describe '#initialize' do
      it 'initializes with relationships data and a store' do
        data   = build_data
        store  = build_store
        object = build_object(data: data, store: store)

        expect(object.data).to  eq data
        expect(object.store).to eq store
      end
    end

    describe '#relationships' do
      it 'returns the relationships' do
        object = build_object
        relationships = object.relationships

        expect(relationships[:account_list]).to be_kind_of DataObject
        expect(relationships[:addresses]).to    be_kind_of DataObjectCollection
        expect(relationships[:emails]).to       be_kind_of NullDataObject
      end
    end

    private

    def build_object(data: build_data, store: build_store)
      RelationshipsObject.new(data, store: store)
    end

    def build_data
      {
        account_list: {
          data: {
            type: 'account_lists',
            id: 'abc123-abc123-abc123-abc123'
          }
        },
        addresses: {
          data: [
            {
              type: 'addresses',
              id: 'def456-def456-def456-def456'
            },
            {
              type: 'addresses',
              id: 'ghi456-ghi456-ghi456-ghi456'
            }
          ]
        },
        emails: {
          data: nil
        }
      }
    end

    def build_store
      ObjectStore.new
    end
  end
end
