require 'spec_helper'
require 'json_api_service/transformer'
require 'json_api_service/configuration'
require 'support/json_api_service_helper'

module JsonApiService
  RSpec.describe Transformer, type: :service do
    include JsonApiServiceHelpers

    describe '.transform' do
      let(:params) { double(:params) }
      let(:configuration) { double(:configuration) }

      let(:transformer) do
        double(:transformer, transform: 'Autobots, transform and ROLL OUT!')
      end

      before do
        allow(Transformer)
          .to receive(:new)
          .with(params: params, configuration: configuration)
          .and_return(transformer)
      end

      it 'delegates the arguments to a new instance and calls `.transform`' do
        result = Transformer.transform(
          params: params,
          configuration: configuration
        )

        expect(result).to eq 'Autobots, transform and ROLL OUT!'
      end
    end

    describe '#initialize' do
      context 'with an ActionController::Parameters object' do
        let(:params)      { build_params_with({}) }
        let(:transformer) { build_transformer(params: params) }

        it 'initializes with a params object' do
          expect(transformer.params).to eq params
        end
      end

      context 'WITHOUT an ActionController::Parameters object' do
        let(:params) { 'not a params object' }

        it 'raises an ArgumentError' do
          expect { build_transformer(params: params) }
            .to raise_error(ArgumentError)
            .with_message('must provide an ActionController::Parameters object, ie: the params from a controller action')
        end
      end
    end

    describe '#create?' do
      context "when the controller action is 'create'" do
        let(:params) do
          params = {
            action: 'create'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'is true' do
          expect(transformer).to be_create
        end
      end

      context "when the controller action isn't 'create'" do
        let(:params) do
          params = {
            action: 'update'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'is false' do
          expect(transformer).not_to be_create
        end
      end
    end

    describe '#update?' do
      context "when the controller action is 'update'" do
        let(:params) do
          params = {
            action: 'update'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'is true' do
          expect(transformer).to be_update
        end
      end

      context "when the controller action isn't 'create'" do
        let(:params) do
          params = {
            action: 'create'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'is false' do
          expect(transformer).not_to be_update
        end
      end
    end

    describe '#transform' do
      describe 'with no relationships' do
        let(:params) do
          params = {
            data: {
              type: 'mock_contacts',
              attributes: {
                name: 'Steve Rogers'
              }
            },
            action: 'create',
            controller: 'users'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'correctly transforms the values' do
          expected_hash = {
            mock_contact: {
              name: 'Steve Rogers'
            },
            action: 'create',
            controller: 'users'
          }

          expect(transformer.transform).to eq build_params_with(expected_hash)
        end
      end

      describe 'during an INDEX' do
        context 'with filter params' do
          let(:params) do
            params = {
              action: 'index',
              controller: 'mock_contacts',
              filter: {
                mock_account_list_id: 'qwe123'
              }
            }

            build_params_with(params)
          end

          let(:transformer) { build_transformer(params: params) }

          before do
            mock_uuid_reference(
              from: 'qwe123',
              to: 10,
              resource: MockAccountList
            )
          end

          it 'correctly transforms the filter params' do
            expected_hash = {
              action: 'index',
              controller: 'mock_contacts',
              filter: {
                mock_account_list_id: 10
              }
            }

            expect(transformer.transform).to eq build_params_with(expected_hash)
          end
        end
      end

      describe 'with a uuid as the primary id' do
        context 'during a POST' do
          let(:params) do
            params = {
              data: {
                type: 'mock_contacts',
                id: 'abc123',
                attributes: {
                  name: 'Steve Rogers'
                }
              },
              action: 'create',
              controller: 'mock_contacts'
            }

            build_params_with(params)
          end

          let(:transformer) { build_transformer(params: params) }

          it "moves the UUID into the resource's attributes" do
            expected_hash = {
              mock_contact: {
                name: 'Steve Rogers',
                uuid: 'abc123'
              },
              action: 'create',
              controller: 'mock_contacts'
            }

            expect(transformer.transform).to eq build_params_with(expected_hash)
          end
        end

        context 'during a PATCH' do
          let(:params) do
            params = {
              data: {
                type: 'mock_contacts',
                id: 'abc123',
                attributes: {
                  name: 'Steve Rogers'
                }
              },
              action: 'update',
              controller: 'mock_contacts'
            }

            build_params_with(params)
          end

          let(:transformer) { build_transformer(params: params) }

          before { mock_uuid_reference(from: 'abc123', to: 55, resource: MockContact) }

          it "moves the UUID into the resource's attributes and finds the ID" do
            expected_hash = {
              mock_contact: {
                id: 55,
                name: 'Steve Rogers',
                uuid: 'abc123'
              },
              action: 'update',
              controller: 'mock_contacts'
            }

            expect(transformer.transform).to eq build_params_with(expected_hash)
          end
        end
      end

      describe 'with a foreign_key relationship' do
        context 'with indirectly named relationships' do
          let(:params) do
            params = {
              data: {
                type: 'mock_contact_referrals',
                relationships: {
                  referred_by: {
                    data: {
                      type: 'mock_contacts',
                      id: 'abc123'
                    }
                  },
                  referred_to: {
                    data: {
                      type: 'mock_contacts',
                      id: 'def456'
                    }
                  }
                }
              },
              action: 'create'
            }

            build_params_with(params)
          end

          let(:transformer) { build_transformer(params: params) }

          before do
            mock_uuid_reference(
              from: %w(abc123 def456),
              to: [10, 20],
              resource: MockContact
            )
          end

          it 'correctly transforms the values' do
            expected_hash = {
              mock_contact_referral: {
                referred_by_id: 10,
                referred_to_id: 20
              },
              action: 'create'
            }

            expect(transformer.transform).to eq build_params_with(expected_hash)
          end
        end

        context 'with a directly named relationship' do
          let(:params) do
            params = {
              data: {
                type: 'mock_contacts',
                attributes: {
                  name: 'Steve Rogers'
                },
                relationships: {
                  mock_account_list: {
                    data: {
                      type: 'mock_account_lists',
                      id: 'abc123'
                    }
                  }
                }
              },
              action: 'create'
            }

            build_params_with(params)
          end

          let(:transformer) { build_transformer(params: params) }

          before { mock_uuid_reference(from: 'abc123', to: 5, resource: MockAccountList) }

          it 'correctly transforms the values' do
            expected_hash = {
              mock_contact: {
                mock_account_list_id: 5,
                name: 'Steve Rogers'
              },
              action: 'create'
            }

            expect(transformer.transform).to eq build_params_with(expected_hash)
          end
        end
      end

      describe 'with a nested relationships' do
        let(:params) do
          params = {
            data: {
              type: 'mock_contacts',
              attributes: {
                name: 'Steve Rogers'
              },
              relationships: {
                mock_addresses: {
                  data: [
                    {
                      id: 'addresses-uuid-abc123',
                      type: 'mock_addresses',
                      attributes: {
                        location: 'Home',
                        city: 'Fremont',
                        street: '123 Somewhere St',
                        state: 'CA',
                        country: 'United States'
                      }
                    },
                    {
                      id: 'addresses-uuid-def456',
                      type: 'mock_addresses',
                      attributes: {
                        location: 'Work',
                        city: 'Orlando',
                        street: '100 Lake Hart Drive',
                        state: 'FL',
                        country: 'United States'
                      }
                    }
                  ]
                }
              }
            },
            action: 'create'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'correctly transforms the values' do
          expected_hash = {
            mock_contact: {
              name: 'Steve Rogers',
              mock_addresses_attributes: {
                0 => {
                  location: 'Home',
                  city: 'Fremont',
                  street: '123 Somewhere St',
                  state: 'CA',
                  country: 'United States',
                  uuid: 'addresses-uuid-abc123'
                },
                1 => {
                  location: 'Work',
                  city: 'Orlando',
                  street: '100 Lake Hart Drive',
                  state: 'FL',
                  country: 'United States',
                  uuid: 'addresses-uuid-def456'
                }
              }
            },
            action: 'create'
          }

          expect(transformer.transform).to eq build_params_with(expected_hash)
        end
      end

      describe 'with nested > nested relationships' do
        let(:params) do
          params = {
            data: {
              type: 'mock_contacts',
              attributes: {
                name: 'Steve Rogers'
              },
              relationships: {
                mock_people: {
                  data: [
                    {
                      type: 'mock_people',
                      attributes: {
                        first_name: 'Steve',
                        last_name: 'Rogers'
                      },
                      relationships: {
                        mock_email_addresses: {
                          data: [
                            {
                              type: 'mock_emails',
                              attributes: {
                                email: 'ca@avengers.co'
                              }
                            }
                          ]
                        }
                      }
                    }
                  ]
                }
              }
            },
            action: 'create'
          }

          build_params_with(params)
        end

        let(:transformer) { build_transformer(params: params) }

        it 'correctly transforms the values' do
          expected_hash = {
            mock_contact: {
              name: 'Steve Rogers',
              mock_people_attributes: {
                0 => {
                  first_name: 'Steve',
                  last_name: 'Rogers',
                  mock_email_addresses_attributes: {
                    0 => {
                      email: 'ca@avengers.co'
                    }
                  }
                }
              }
            },
            action: 'create'
          }

          expect(transformer.transform).to eq build_params_with(expected_hash)
        end
      end
    end

    def build_transformer(params:, configuration: Configuration.new)
      Transformer.new(params: params, configuration: configuration)
    end
  end
end
