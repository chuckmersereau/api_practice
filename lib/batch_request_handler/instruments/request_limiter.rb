module BatchRequestHandler
  module Instruments
    class RequestLimiter < BatchRequestHandler::Instrument
      def initialize(_params)
        @is_bad_request = false
      end

      def around_perform_requests(requests)
        if requests.length <= 100
          yield requests
        else
          @is_bad_request = true
          [] # returning that there are no requests being processed
        end
      end

      def around_build_response(json_responses)
        if @is_bad_request
          bad_request_response
        else
          yield json_responses
        end
      end

      private

      def bad_request_response
        [
          429,
          {
            'Content-Type' => 'application/json'
          },
          [
            {
              errors: [
                {
                  status: 429,
                  title:  'Too Many Requests',
                  detail: 'You only able to send up to 100 requests in a batch request'
                }
              ]
            }.to_json
          ]
        ]
      end
    end
  end
end
