require 'rails_helper'

describe ApiController do
  let!(:user) { create(:user_with_account) }
  let(:default_type) { ApiController::DEFAULT_SUPPORTED_CONTENT_TYPE }

  controller(ApiController) do
    def show
      head :no_content
    end
  end

  before do
    routes.draw { get 'show' => 'api#show' }
    api_login(user)
  end

  context '#supports_content_types' do
    after(:each) do
      ApiController.supports_content_types(nil)
      raise 'State was not properly reset!' if ApiController.supported_content_types != [default_type]
    end

    it 'supports additional content types' do
      ApiController.supports_content_types('my-special-type', 'my-other-content-type')
      expect(ApiController.supported_content_types).to eq ['my-special-type', 'my-other-content-type']
    end

    it 'supports a default content type' do
      expect(ApiController.supported_content_types).to include default_type
    end
  end

  context '#supports_accept_header_content_types' do
    after(:each) do
      ApiController.supports_accept_header_content_types(nil)
      raise 'State was not properly reset!' if ApiController.supported_accept_header_content_types != [default_type]
    end

    it 'supports additional content types in accept header' do
      ApiController.supports_accept_header_content_types('my-special-type', 'my-other-content-type')
      expect(ApiController.supported_accept_header_content_types).to eq %w(my-special-type my-other-content-type)
    end

    it 'supports a default content type in accept header' do
      expect(ApiController.supported_accept_header_content_types).to include default_type
    end
  end

  it 'successfully handles a request with nil content type' do
    request.headers['CONTENT_TYPE'] = nil
    get :show
  end
end
