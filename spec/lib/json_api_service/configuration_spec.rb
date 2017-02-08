require 'spec_helper'
require 'json_api_service/configuration'
require 'support/json_api_service_helper'

module JsonApiService
  RSpec.describe Configuration, type: :service do
    let(:configuration) { Configuration.new }

    describe '#initialize' do
      it 'initializes with a fresh ResourceLookup' do
        expect(configuration.resource_lookup).to be_a ResourceLookup
      end

      it 'initializes with an empty hash for ignored_foreign_keys' do
        expect(configuration.ignored_foreign_keys).to be_empty
      end
    end

    describe '#custom_references' do
      before do
        allow_any_instance_of(ResourceLookup)
          .to receive(:custom_references)
          .and_return(users: 'UserAccounts')
      end

      it 'returns the custom_references of the lookup' do
        expect(configuration.custom_references)
          .to eq(users: 'UserAccounts')
      end
    end

    describe '#custom_references=' do
      it 'assigns new custom_references' do
        expect(configuration.custom_references).to eq({})
        configuration.custom_references = { users: 'UserAccounts' }
        expect(configuration.custom_references).to eq(users: 'UserAccounts')
      end
    end

    describe '#ignored_foreign_keys' do
      it 'returns an empty array as a default value' do
        expect(configuration.ignored_foreign_keys).to eq({})
        expect(configuration.ignored_foreign_keys[:missing]).to eq([])
      end
    end

    describe '#ignored_foreign_keys=' do
      it 'assigns new ignored_foreign_keys' do
        expect(configuration.ignored_foreign_keys).to eq({})
        configuration.ignored_foreign_keys = { donations: [:remote_id] }
        expect(configuration.ignored_foreign_keys).to eq(donations: [:remote_id])
      end

      it 'still returns an empty array as a default value' do
        configuration.ignored_foreign_keys = { donations: [:remote_id] }
        expect(configuration.ignored_foreign_keys[:missing]).to eq([])
      end
    end
  end
end
