module Auth
  class Engine < ::Rails::Engine
    isolate_namespace Auth
    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end
    middleware.use ActionDispatch::Cookies
    middleware.use ActionDispatch::Session::CookieStore, key: '_mpdx_session'
  end
end
