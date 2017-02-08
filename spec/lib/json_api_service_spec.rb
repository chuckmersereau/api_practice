require 'spec_helper'
require 'json_api_service'

RSpec.describe JsonApiService, type: :service do
  describe '.consume' do
    let(:params)             { double(:params) }
    let(:context)            { double(:context) }
    let(:transformed_params) { double(:transformed_params) }
    let(:configuration)      { JsonApiService.configuration }

    before do
      allow(JsonApiService::Validator)
        .to receive(:validate!)
        .with(params: params, context: context, configuration: configuration)
        .and_return(true)

      allow(JsonApiService::Transformer)
        .to receive(:transform)
        .with(params: params, configuration: configuration)
        .and_return(transformed_params)
    end

    it 'delegates to the validator and transformer, returning new params' do
      expect(JsonApiService::Validator)
        .to receive(:validate!)
        .with(params: params, context: context, configuration: configuration)

      expect(JsonApiService::Transformer)
        .to receive(:transform)
        .with(params: params, configuration: configuration)

      result = JsonApiService.consume(params: params, context: context)

      expect(result).to eq transformed_params
    end
  end
end
