require 'spec_helper'
require 'json_api_service/validator'
require 'json_api_service/errors'
require 'json_api_service/configuration'
require 'support/json_api_service_helper'

module JsonApiService
  RSpec.describe Validator, type: :service do
    include JsonApiServiceHelpers

    let(:configuration) do
      Configuration.new.tap do |config|
        config.ignored_foreign_keys = {
          users: [:remote_id]
        }
      end
    end

    let(:validator) do
      Validator.new(
        params: params,
        configuration: configuration,
        context: controller
      )
    end

    describe '#initialize' do
      let(:params)     { double(:params) }
      let(:controller) { double(:controller) }

      it 'initializes with params and with a controller instance for context' do
        expect(validator.params).to  eq params
        expect(validator.context).to eq controller
      end
    end

    describe '#validate!' do
      context 'with a primary id in #attributes' do
        let(:controller) { double(:controller, resource_type: 'users') }

        context 'on a POST' do
          let(:params) do
            params = {
              data: {
                type: 'users',
                attributes: {
                  id: 'abc123'
                }
              },
              action: 'create'
            }

            build_params_with(params)
          end

          it 'raises an error' do
            message = invalid_primary_key_placement('/data/attributes/id', '/data/id')

            expect { validator.validate! }
              .to raise_error(InvalidPrimaryKeyPlacementError)
              .with_message(message)
          end
        end
      end

      context 'with a primary id in nested #attributes' do
        let(:controller) { double(:controller, resource_type: 'users') }

        context 'on a POST' do
          let(:params) do
            params = {
              data: {
                type: 'users',
                relationships: {
                  people: {
                    data: [
                      {
                        type: 'people',
                        relationships: {
                          email_addresses: {
                            data: [
                              {
                                type: 'email_addresses',
                                attributes: {
                                  id: 'abc123', # invalid placement
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

          it 'raises an error' do
            message = invalid_primary_key_placement(
              '/data/relationships/people/data/0/relationships/email_addresses/data/0/attributes/id',
              '/data/relationships/people/data/0/relationships/email_addresses/data/0/id'
            )

            expect { validator.validate! }
              .to raise_error(InvalidPrimaryKeyPlacementError)
              .with_message(message)
          end
        end
      end

      context 'with an invalid resource_type' do
        let(:controller) { double(:controller, resource_type: 'users') }

        context 'on a POST' do
          let(:params) do
            params = {
              data: {
                type: 'contacts'
              },
              action: 'create'
            }

            build_params_with(params)
          end

          it 'raises an error' do
            expect { validator.validate! }
              .to raise_error(InvalidTypeError)
              .with_message("'contacts' is not a valid resource type for this endpoint. Expected 'users' instead")
          end
        end

        context 'on a PATCH' do
          let(:params) do
            params = {
              data: {
                type: 'contacts'
              },
              action: 'update'
            }

            build_params_with(params)
          end

          it 'raises an error' do
            expect { validator.validate! }
              .to raise_error(InvalidTypeError)
              .with_message("'contacts' is not a valid resource type for this endpoint. Expected 'users' instead")
          end
        end
      end

      context 'with an missing resource_type' do
        let(:controller) { double(:controller, resource_type: 'users') }

        context 'on an INDEX' do
          let(:params) do
            params = {
              data: {
                type: nil # missing
              },
              action: 'index'
            }

            build_params_with(params)
          end

          it "doesn't raise an error" do
            expect { validator.validate! }.not_to raise_error
          end
        end

        context 'on a POST' do
          let(:params) do
            params = {
              data: {
                type: nil # missing
              },
              action: 'create'
            }

            build_params_with(params)
          end

          it 'raises an error' do
            message = missing_type_error('/data/type')

            expect { validator.validate! }
              .to raise_error(MissingTypeError)
              .with_message(message)
          end
        end

        context 'on a PATCH' do
          let(:params) do
            params = {
              data: {
                type: nil # missing
              },
              action: 'update'
            }

            build_params_with(params)
          end

          it 'raises an error' do
            message = missing_type_error('/data/type')

            expect { validator.validate! }
              .to raise_error(MissingTypeError)
              .with_message(message)
          end
        end
      end

      context 'with an missing resource_type in a relationship object' do
        let(:controller) { double(:controller, resource_type: 'users') }

        context 'on an INDEX' do
          let(:params) do
            params = {
              data: {
                type: 'users',
                relationships: {
                  account_list: {
                    data: {
                      type: nil # missing
                    }
                  },
                  addresses: {
                    data: [
                      {
                        type: nil # missing
                      }
                    ]
                  }
                }
              },
              action: 'index'
            }

            build_params_with(params)
          end

          it "doesn't raise an error" do
            expect { validator.validate! }.not_to raise_error
          end
        end

        context 'with a foreign_key relationship' do
          context 'on a POST' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  relationships: {
                    account_list: {
                      data: {
                        type: nil # missing
                      }
                    }
                  }
                },
                action: 'create'
              }

              build_params_with(params)
            end

            it 'raises an error' do
              message = missing_type_error('/data/relationships/account_list/data/type')

              expect { validator.validate! }
                .to raise_error(MissingTypeError)
                .with_message(message)
            end
          end

          context 'on a PATCH' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  relationships: {
                    account_list: {
                      data: {
                        type: nil # missing
                      }
                    }
                  }
                },
                action: 'update'
              }

              build_params_with(params)
            end

            it 'raises an error' do
              message = missing_type_error('/data/relationships/account_list/data/type')

              expect { validator.validate! }
                .to raise_error(MissingTypeError)
                .with_message(message)
            end
          end
        end

        context 'with a nested relationship' do
          context 'on a POST' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  relationships: {
                    people: {
                      data: [
                        {
                          type: 'people',
                          relationships: {
                            email_addresses: {
                              data: [
                                {
                                  type: nil, # missing
                                  email: 'ca@avengers.co'
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

            it 'raises an error' do
              message = missing_type_error('/data/relationships/people/data/0/relationships/email_addresses/data/0/type')

              expect { validator.validate! }
                .to raise_error(MissingTypeError)
                .with_message(message)
            end
          end

          context 'on a PATCH' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  relationships: {
                    people: {
                      data: [
                        {
                          type: 'people',
                          relationships: {
                            email_addresses: {
                              data: [
                                {
                                  type: nil, # missing
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
                action: 'update'
              }

              build_params_with(params)
            end

            it 'raises an error' do
              message = missing_type_error('/data/relationships/people/data/0/relationships/email_addresses/data/0/type')

              expect { validator.validate! }
                .to raise_error(MissingTypeError)
                .with_message(message)
            end
          end
        end

        context "with a foreign_key in the object's #attributes" do
          context 'on a POST (and with nested resources)' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  relationships: {
                    people: {
                      data: [
                        {
                          type: 'people',
                          relationships: {
                            email_addresses: {
                              data: [
                                {
                                  type: 'email-addresses',
                                  attributes: {
                                    email: 'ca@avengers.co',
                                    account_list_id: 10
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

            it 'raises an error' do
              message = foreign_key_error('/data/relationships/people/data/0/relationships/email_addresses/data/0/attributes/account_list_id')

              expect { validator.validate! }
                .to raise_error(ForeignKeyPresentError)
                .with_message(message)
            end
          end

          context 'on a PATCH' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  attributes: {
                    account_list_id: 5
                  }
                },
                action: 'update'
              }

              build_params_with(params)
            end

            it 'raises an error' do
              message = foreign_key_error('/data/attributes/account_list_id')

              expect { validator.validate! }
                .to raise_error(ForeignKeyPresentError)
                .with_message(message)
            end
          end

          context 'when a foreign_key attribute is configured to be ignored' do
            let(:params) do
              params = {
                data: {
                  type: 'users',
                  attributes: {
                    remote_id: 'abc123'
                  }
                },
                action: 'update'
              }

              build_params_with(params)
            end

            it 'raises an error' do
              expect { validator.validate! }.not_to raise_error
            end
          end
        end
      end
    end

    context 'with invalid includes' do
      let(:controller) { double(:controller, resource_type: 'contacts') }

      context 'with a missing type' do
        let(:params) do
          params = {
            included: [
              {
                type: 'comments',
                id: 'uuid-comments-1'
              },
              {
                type: nil, # missing
                id: 'uuid-missing-type'
              }
            ],
            data: {
              type: 'contacts',
              id: 'uuid-contacts-1'
            },
            action: 'create'
          }

          build_params_with(params)
        end

        it 'raises an error' do
          message = missing_type_error('/included/1/type')

          expect { validator.validate! }
            .to raise_error(MissingTypeError)
            .with_message(message)
        end
      end

      context 'with a foreign key' do
        let(:params) do
          params = {
            included: [
              {
                type: 'comments',
                id: 'uuid-comments-1'
              },
              {
                type: 'addresses',
                id: 'uuid-addresses-1',
                attributes: {
                  contact_id: 'uuid-contacts-1'
                }
              }
            ],
            data: {
              type: 'contacts',
              id: 'uuid-contacts-1'
            },
            action: 'create'
          }

          build_params_with(params)
        end

        it 'raises an error' do
          message = foreign_key_error('/included/1/attributes/contact_id')

          expect { validator.validate! }
            .to raise_error(ForeignKeyPresentError)
            .with_message(message)
        end
      end
    end

    def foreign_key_error(pointer_ref)
      "Foreign keys SHOULD NOT be referenced in the #attributes of a JSONAPI resource object. Reference: #{pointer_ref}"
    end

    def missing_type_error(pointer_ref)
      "JSONAPI resource objects MUST contain a `type` top-level member of its hash for POST and PATCH requests. Expected to find a `type` member at #{pointer_ref}"
    end

    def invalid_primary_key_placement(actual_pointer_ref, expected_pointer_ref)
      [
        'A primary key, if sent in a request, CANNOT be referenced in the #attributes of a JSONAPI resource object.',
        "It must instead be sent as a top level member of the resource's `data` object. Reference: `#{actual_pointer_ref}`. Expected `#{expected_pointer_ref}`"
      ].join(' ')
    end
  end
end
