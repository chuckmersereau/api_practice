require 'spec_helper'
require 'json_api_service/uuid_to_id_reference_fetcher'
require 'json_api_service/configuration'
require 'support/json_api_service_helper'

module JsonApiService
  RSpec.describe UuidToIdReferenceFetcher, type: :service do
    include JsonApiServiceHelpers

    let(:params) do
      params = {
        data: {
          type: 'mock_contacts',
          id: 'contact-uuid-abc123',
          attributes: {
            name: 'Steve Rogers'
          },
          relationships: {
            people: {
              data: [
                {
                  type: 'mock_people',
                  id: 'person-uuid-abc123',
                  attributes: {
                    first_name: 'Steve',
                    last_name: 'Rogers'
                  },
                  relationships: {
                    email_addresses: {
                      data: [
                        {
                          type: 'mock_emails',
                          id: 'email-uuid-abc123',
                          attributes: {
                            email: 'ca@avengers.co'
                          }
                        }
                      ]
                    }
                  }
                },
                {
                  type: 'mock_people',
                  id: 'person-uuid-def456', attributes: {
                    first_name: 'Tony',
                    last_name: 'Stark'
                  },
                  relationships: {
                    email_addresses: {
                      data: [
                        {
                          type: 'mock_emails',
                          id: 'email-uuid-def456',
                          attributes: {
                            email: 'ironman@avengers.co'
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
        filter: {
          mock_account_list_id: 'account-list-uuid-abc123',
          mock_contact_id: 'contact-uuid-abc123, contact-uuid-def456'
        }
      }

      build_params_with(params)
    end

    let(:fetcher) { build_fetcher(params: params) }

    describe '#initialize' do
      it 'initializes with params' do
        expect(fetcher.params).to eq params
      end
    end

    describe '#uuids' do
      it 'returns a mapping of UUIDs to type from the params' do
        expected_uuids = {
          mock_emails: [
            'email-uuid-abc123',
            'email-uuid-def456'
          ],
          mock_contacts: [
            'contact-uuid-abc123',
            'contact-uuid-def456'
          ],
          mock_people: [
            'person-uuid-abc123',
            'person-uuid-def456'
          ],
          mock_account_lists: [
            'account-list-uuid-abc123'
          ]
        }

        expect(fetcher.uuids).to eq HashWithIndifferentAccess.new(expected_uuids)
      end
    end

    describe '#[]()' do
      before do
        mock_uuid_reference(
          from: ['contact-uuid-abc123', 'contact-uuid-def456'],
          to: [50, 100],
          resource: MockContact
        )

        mock_uuid_reference(
          from: ['person-uuid-abc123', 'person-uuid-def456'],
          to: [12, 24],
          resource: MockPerson
        )

        mock_uuid_reference(
          from: ['account-list-uuid-abc123'],
          to: [20],
          resource: MockAccountList
        )
      end

      context 'the first time' do
        it 'fetches the ids from the resource and uuid' do
          expect(MockContact)
            .to receive(:where)
            .with(uuid: ['contact-uuid-abc123', 'contact-uuid-def456'])

          fetcher[:mock_contacts]
        end

        it 'returns the correct format' do
          expected_results = {
            'person-uuid-abc123' => 12,
            'person-uuid-def456' => 24
          }

          expect(fetcher[:mock_people]).to eq expected_results
        end
      end

      context 'the second time' do
        before { fetcher[:mock_contacts] }

        it "doesn't fetch again" do
          expect(MockContact)
            .not_to receive(:where)
            .with(uuid: ['contact-uuid-abc123'])

          fetcher[:mock_contacts]
        end
      end
    end

    describe '#fetch' do
      before do
        mock_uuid_reference(
          from: ['contact-uuid-abc123', 'contact-uuid-def456'],
          to: [50, 100],
          resource: MockContact
        )

        mock_uuid_reference(
          from: ['person-uuid-abc123', 'person-uuid-def456'],
          to: [12, 24],
          resource: MockPerson
        )

        mock_uuid_reference(
          from: ['email-uuid-abc123', 'email-uuid-def456'],
          to: [1, 5],
          resource: MockEmail
        )

        mock_uuid_reference(
          from: ['account-list-uuid-abc123'],
          to: [20],
          resource: MockAccountList
        )
      end

      it 'fetches all the references' do
        expect(MockContact)
          .to receive(:where)
          .with(uuid: ['contact-uuid-abc123', 'contact-uuid-def456'])

        expect(MockPerson)
          .to receive(:where)
          .with(uuid: ['person-uuid-abc123', 'person-uuid-def456'])

        expect(MockEmail)
          .to receive(:where)
          .with(uuid: ['email-uuid-abc123', 'email-uuid-def456'])

        fetcher.fetch
      end

      it 'returns the correct values' do
        expected_results = {
          mock_contacts: {
            'contact-uuid-abc123' => 50,
            'contact-uuid-def456' => 100
          },
          mock_people: {
            'person-uuid-abc123' => 12,
            'person-uuid-def456' => 24
          },
          mock_emails: {
            'email-uuid-abc123' => 1,
            'email-uuid-def456' => 5
          },
          mock_account_lists: {
            'account-list-uuid-abc123' => 20
          }
        }

        expect(fetcher.fetch).to eq HashWithIndifferentAccess.new(expected_results)
      end
    end

    def build_fetcher(params:, configuration: Configuration.new)
      UuidToIdReferenceFetcher.new(params: params, configuration: configuration)
    end
  end
end
