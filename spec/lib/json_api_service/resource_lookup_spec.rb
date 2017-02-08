require 'spec_helper'
require 'json_api_service/resource_lookup'
require 'support/json_api_service_helper'

module JsonApiService
  RSpec.describe ResourceLookup, type: :service do
    include JsonApiServiceHelpers

    let(:custom_references) do
      {
        mock_facebook_accounts: 'MockPerson::FacebookAccount'
      }
    end

    describe '#custom_references' do
      context 'by default' do
        let(:lookup) { ResourceLookup.new }

        it 'is empty' do
          expect(lookup.custom_references).to be_empty
        end
      end

      context 'when initialized with references' do
        let(:lookup) { ResourceLookup.new(custom_references) }

        it 'uses those references' do
          expect(lookup.custom_references).to eq custom_references
        end
      end
    end

    describe '#find' do
      let(:lookup) { ResourceLookup.new(custom_references) }

      context 'with a singular type' do
        let(:type) { 'mock_contact' }

        it 'returns the correct Resource' do
          expect(lookup.find(type)).to eq MockContact
        end
      end

      context 'with a pluralized type' do
        let(:type) { 'mock_contacts' }

        it 'returns the correct Resource' do
          expect(lookup.find(type)).to eq MockContact
        end
      end

      context 'with a type that requires a custom reference' do
        let(:type) { 'mock_facebook_accounts' }

        it 'returns the correct Resource' do
          expect(lookup.find(type)).to eq MockPerson::FacebookAccount
        end
      end
    end
  end
end
