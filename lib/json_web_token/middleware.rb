module JsonWebToken
  class Middleware
    API_V2_ENDPOINT ||= '/api/v2/'.freeze

    def initialize(app, &block)
      @app = app
      @after_decode = block
    end

    def call(env)
      add_jwt_payload_to_request_environment(env) if api_v2_request?(env)
      @app.call(env)
    end

    private

    def api_v2_request?(env)
      env['PATH_INFO']&.starts_with? API_V2_ENDPOINT
    end

    def add_jwt_payload_to_request_environment(env)
      jwt_payload = fetch_jwt_payload(env)

      if jwt_payload
        env['auth.jwt_payload'] = jwt_payload
        @after_decode.call(env) if @after_decode
      end
    end

    def fetch_auth_header(env)
      env['HTTP_AUTHORIZATION']
    end

    def fetch_http_token(env)
      auth_header = fetch_auth_header(env)

      auth_header.split(' ').last if auth_header.present?
    end

    def fetch_jwt_payload(env)
      http_token = fetch_http_token(env)
      ::JsonWebToken.decode(http_token) if http_token
    end
  end
end
