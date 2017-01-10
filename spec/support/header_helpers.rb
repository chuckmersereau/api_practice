module HeaderHelpers
  extend ActiveSupport::Concern
  included do
    before(:each) do
      request.headers['CONTENT_TYPE'] = 'application/vnd.api+json'
    end
  end
end
