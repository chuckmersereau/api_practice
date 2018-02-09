module BatchRequestHandler
  class Middleware
    BATCH_ENDPOINT = '/api/v2/batch'.freeze

    def initialize(app, endpoint: BATCH_ENDPOINT, instruments: [])
      @app = app
      @endpoint = endpoint
      @instrument_classes = instruments.map(&:safe_constantize)
    end

    def call(env)
      if batch_request?(env)
        handle_batch_request(env)
      else
        @app.call(env)
      end
    end

    private

    def batch_request?(env)
      request_path_matches?(env) && env['REQUEST_METHOD'] == 'POST'
    end

    def request_path_matches?(env)
      request_path = env['PATH_INFO'].to_s.squeeze('/')

      request_path[0, @endpoint.length] == @endpoint &&
        (request_path[@endpoint.length].nil? || request_path[@endpoint.length] == '/')
    end

    def handle_batch_request(env)
      batch_request = ::BatchRequestHandler::BatchRequest.new(env)

      @instrument_classes.each do |instrument_class|
        batch_request.add_instrumentation(instrument_class)
      end

      batch_request.process(@app)
    rescue ::BatchRequestHandler::BatchRequest::InvalidBatchRequestError
      render_invalid_batch_request_response
    rescue StandardError => e
      Rollbar.error(e)
      render_unknown_error_response
    end

    def invalid_batch_request_message
      [
        'Invalid batch request.',
        'A batch request must have a body of a JSON object with a `requests` key that has an array of request objects.',
        'A request object must have a `method`, and a `path`, and optionally a `body`.',
        'The `body` must be a string.'
      ].join
    end

    def render_invalid_batch_request_response
      json_payload = {
        errors: [
          {
            status: 400,
            message: invalid_batch_request_message
          }
        ]
      }.to_json
      [400, { 'Content-Type' => 'application/json' }, [json_payload]]
    end

    def render_unknown_error_response
      json_payload = {
        errors: [
          {
            status: 500,
            message: 'There was an unknown error in the batch request handler. The error has been logged.'
          }
        ]
      }.to_json
      [500, { 'Content-Type' => 'application/json' }, [json_payload]]
    end
  end
end
