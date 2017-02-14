require 'spec_helper'
require 'json_api_service/data_object'
require 'json_api_service/object_store'
require 'json_api_service/relationships_object'

module JsonApiService
  RSpec.describe DataObject do
    describe '#initialize' do
      it 'initializes with data and a store' do
        data   = build_data
        store  = build_store
        object = build_object(data: data, store: store)

        expect(object.data).to  eq data
        expect(object.store).to eq store
      end
    end

    describe '#id' do
      it 'pulls the id from the object data' do
        data = {
          id: 'abc123-abc123-abc123-abc123'
        }

        object = build_object(data: data)
        expect(object.id).to eq 'abc123-abc123-abc123-abc123'
      end
    end

    describe '#attributes' do
      it 'pulls the attributes from the object data' do
        data = {
          attributes: {
            first_name: 'Steve',
            last_name: 'Rogers'
          }
        }

        object = build_object(data: data)
        expect(object.attributes).to eq data[:attributes]
      end
    end

    describe '#relationships' do
      it 'pulls and converts the relationships from the object data' do
        object = build_object
        expect(object.relationships).to be_kind_of RelationshipsObject
      end
    end

    describe '#type' do
      it 'pulls the type from the object data' do
        data = {
          type: 'users'
        }

        object = build_object(data: data)
        expect(object.type).to eq 'users'
      end
    end

    describe '#to_h' do
      it 'turns the objects back into a hash' do
        object = build_object
        expect(object.to_h).to eq build_data
      end
    end

    describe '#merge' do
      it 'pulls the attributes / relationships from another object if missing' do
        initial_data = {
          type: 'users',
          id: 'abc-123',
          attributes: {},
          relationships: {}
        }

        initial_object = build_object(data: initial_data)

        alternate_data = {
          type: 'users',
          id: 'abc-123',
          attributes: {
            name: 'Steve Rogers'
          },
          relationships: {
            account_list: {
              data: {
                type: 'account_lists',
                id: 'uuid-account-list'
              }
            }
          }
        }

        alternate_object = build_object(data: alternate_data)

        expect(initial_object.attributes)   .to be_empty
        expect(initial_object.relationships).to be_empty

        initial_object.merge(alternate_object)

        expect(initial_object.attributes)   .to eq alternate_object.attributes
        expect(initial_object.relationships).to eq alternate_object.relationships
      end
    end

    describe '#validate_against_store' do
      let(:store) { build_store }

      before do
        contact_data = {
          type: 'contacts',
          id: 'uuid-contact',
          attributes: {
            first_name: 'Tony',
            last_name: 'Stark'
          }
        }

        email_data = {
          type: 'emails',
          id: 'uuid-email',
          attributes: {
            email: 'ironman@avengers.co'
          }
        }

        # ensure store already has data
        build_object(data: contact_data, store: store)
        build_object(data: email_data, store: store)
      end

      it 'will fetch attributes from stored versions if they exist' do
        data = {
          type: 'contacts',
          id: 'uuid-contact',
          attributes: {}, # empty on purpose
          relationships: {
            emails: {
              data: [
                {
                  type: 'emails',
                  id: 'uuid-email'
                }
              ]
            }
          }
        }

        object = build_object(data: data, store: store)

        expect(store['contacts'][object.id]).not_to eq object
        expect(object.attributes).to be_empty
        expect(object.relationships[:emails].first.attributes).to be_empty

        object.validate_against_store

        expect(object.attributes).to eq(
          first_name: 'Tony',
          last_name: 'Stark'
        )
        expect(object.relationships[:emails].first.attributes).to eq(
          email: 'ironman@avengers.co'
        )

        expect(store['contacts'][object.id]).to eq object
      end
    end

    private

    def build_data
      {
        type: 'contacts',
        id: 'abc123-abc123-abc123-abc123',
        attributes: {
          first_name: 'Steve',
          last_name: 'Rogers'
        },
        relationships: {
          account_list: {
            data: {
              type: 'account_lists',
              id: 'abc123-abc123-abc123-abc123-'
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
          }
        }
      }
    end

    def build_object(data: build_data, store: build_store)
      DataObject.new(data, store: store)
    end

    def build_store
      ObjectStore.new
    end
  end
end
