module BatchRequestHandler
  module Instruments
    class RequestValidator < BatchRequestHandler::Instrument
      VALID_BATCH_METHODS = %w(GET POST PUT PATCH DELETE).freeze

      class InvalidBatchRequestError < StandardError
        DEFAULT_MESSAGE = 'This request is unable to be performed as part of a batch request'.freeze

        attr_reader :message, :status

        def initialize(message: DEFAULT_MESSAGE, status: 400)
          @message = message
          @status = status
        end
      end

      def around_perform_request(env)
        rack_request = Rack::Request.new(env)
        validate_request!(rack_request)
        yield env
      rescue InvalidBatchRequestError => error
        invalid_batch_request_error_response(error, rack_request)
      end

      def self.generate_invalid_batch_request_json_payload(error, rack_request)
        {
          errors: [
            {
              status: error.status,
              message: error.message,
              meta: {
                method: rack_request.request_method,
                path: rack_request.path,
                body: rack_request.body.read
              }
            }
          ]
        }
      end

      private

      def validate_request!(rack_request)
        allowed_method?(rack_request)
        path_present?(rack_request)
      end

      def allowed_method?(rack_request)
        return if rack_request.request_method.in?(VALID_BATCH_METHODS)
        raise InvalidBatchRequestError,
              message: "HTTP method `#{rack_request.request_method}` is not allowed in a batch request",
              status: 405
      end

      def path_present?(rack_request)
        return if rack_request.path.present?
        raise InvalidBatchRequestError,
              message: 'The `path` key must be provided as part of a request object in a batch request'
      end

      def invalid_batch_request_error_response(error, rack_request)
        json_response = self.class.generate_invalid_batch_request_json_payload(error, rack_request)
        body = JSON.dump(json_response)

        [error.status, { 'Content-Type' => 'application/json' }, [body]]
      end
    end
  end
end
