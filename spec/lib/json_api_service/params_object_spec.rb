require 'spec_helper'
require 'json_api_service/params_object'

module JsonApiService
  RSpec.describe ParamsObject do
    describe '#initialize' do
      it 'initializes with a params hash' do
        params = build_params
        object = ParamsObject.new(params: params)

        expect(object.params).to eq params
      end

      it 'initializes with a store' do
        object = build_object
        expect(object.store).to be_kind_of ObjectStore
      end

      it 'parses the param data' do
        object = build_object
        expect(object.data).to be_kind_of DataObject
      end

      it 'parses the included objects into the store' do
        store = ObjectStore.new

        params = {
          included: [
            {
              type: 'users',
              id: 'id-users-1',
              attributes: {
                name: 'Tony Stark'
              }
            },
            {
              type: 'contacts',
              id: 'id-contacts-1',
              attributes: {
                first_name: 'Steve',
                last_name: 'Rogers'
              }
            }
          ]
        }

        expect(store['contacts']).to be_empty
        expect(store['users']).to    be_empty

        object = build_object(params: params, store: store)
        store  = object.store

        expect(store['contacts']['id-contacts-1']).not_to be_nil
        expect(store['users']['id-users-1']).not_to       be_nil
      end
    end

    describe 'Sanity Check' do
      it 'correctly converts the params' do
        object = build_object(params: sanity_params)
        expect(object.to_h).to eq expected_sanity_output
      end
    end

    def build_object(params: build_params, store: ObjectStore.new)
      ParamsObject.new(params: params, store: store)
    end

    def build_params
      {
        data: {
          type: 'contacts',
          id: 'id-contacts-1'
        },
        included: [
          {
            type: 'users',
            id: 'id-users-1',
            attributes: {
              name: 'Tony Stark'
            }
          }
        ]
      }
    end

    def sanity_params
      {
        included: [
          {
            type: 'mock_people',
            id: '10e9f7f5-b027-4e04-8192-b9b698ac0b18',
            attributes: {
              first_name: 'Mike'
            }
          },
          {
            type: 'mock_comments',
            id: '91374910-ef15-11e6-8787-ef17a057947e',
            attributes: {
              body: 'I love Orange Soda'
            },
            relationships: {
              mock_person: {
                data: {
                  type: 'mock_people',
                  id: '10e9f7f5-b027-4e04-8192-b9b698ac0b18'
                }
              }
            }
          }
        ],
        data: {
          type: 'mock_tasks',
          attributes: {
            activity_type: 'Appointment',
            start_at: '2017-02-09T22:17:28.854Z',
            subject: 'An appointment to talk about Orange Soda'
          },
          relationships: {
            mock_account_list: {
              data: {
                type: 'mock_account_lists',
                id: '144b83e8-b7f6-48c8-9c0e-688785bf6164'
              }
            },
            mock_comments: {
              data: [
                {
                  type: 'mock_comments',
                  id: '91374910-ef15-11e6-8787-ef17a057947e'
                }
              ]
            }
          }
        },
        action: 'create'
      }
    end

    def expected_sanity_output
      {
        data: {
          type: 'mock_tasks',
          attributes: {
            activity_type: 'Appointment',
            start_at: '2017-02-09T22:17:28.854Z',
            subject: 'An appointment to talk about Orange Soda'
          },
          relationships: {
            mock_account_list: {
              data: {
                type: 'mock_account_lists',
                id: '144b83e8-b7f6-48c8-9c0e-688785bf6164'
              }
            },
            mock_comments: {
              data: [
                {
                  type: 'mock_comments',
                  id: '91374910-ef15-11e6-8787-ef17a057947e',
                  attributes: {
                    body: 'I love Orange Soda'
                  },
                  relationships: {
                    mock_person: {
                      data: {
                        type: 'mock_people',
                        id: '10e9f7f5-b027-4e04-8192-b9b698ac0b18',
                        attributes: {
                          first_name: 'Mike'
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        },
        action: 'create'
      }
    end
  end
end
