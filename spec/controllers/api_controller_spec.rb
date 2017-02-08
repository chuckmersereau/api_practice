require 'rails_helper'

describe ApiController do
  context '#supports_content_types' do
    after(:each) do
      ApiController.supports_content_types(nil)
      raise 'State was not properly reset!' if ApiController.supported_content_types != [ApiController::DEFAULT_SUPPORTED_CONTENT_TYPE]
    end

    it 'supports additional content types' do
      ApiController.supports_content_types('my-special-type', 'my-other-content-type')
      expect(ApiController.supported_content_types).to eq ['my-special-type', 'my-other-content-type']
    end

    it 'supports a default content type' do
      expect(ApiController.supported_content_types).to include ApiController::DEFAULT_SUPPORTED_CONTENT_TYPE
    end
  end

  context '#supports_accept_header_content_types' do
    after(:each) do
      ApiController.supports_accept_header_content_types(nil)
      raise 'State was not properly reset!' if ApiController.supported_accept_header_content_types != [ApiController::DEFAULT_SUPPORTED_CONTENT_TYPE]
    end

    it 'supports additional content types in accept header' do
      ApiController.supports_accept_header_content_types('my-special-type', 'my-other-content-type')
      expect(ApiController.supported_accept_header_content_types).to eq ['my-special-type', 'my-other-content-type']
    end

    it 'supports a default content type in accept header' do
      expect(ApiController.supported_accept_header_content_types).to include ApiController::DEFAULT_SUPPORTED_CONTENT_TYPE
    end
  end
end
