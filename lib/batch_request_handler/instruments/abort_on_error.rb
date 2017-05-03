module BatchRequestHandler
  module Instruments
    # AbortOnError only runs if the BatchRequest has 'on_error' set to 'ABORT'.
    # It will process through the requests, but if a request errors, it will
    # abort immediately and return only the responses up to and including the
    # error response. It will also change the status of the batch request to be
    # the status of the response from the errored request.
    class AbortOnError < BatchRequestHandler::Instrument
      def self.enabled_for?(batch_request)
        batch_request.params['on_error'] == 'ABORT'
      end

      def initialize(_params)
        # Because the mechanism for aborting early is a catch/throw, throwing
        # will abort early out of the map over the requests, so no responses
        # will get captured by the BatchRequest. So we have to keep track of
        # responses ourselves, and make sure that they get returned in
        # `around_perform_requests`
        @responses = []
        @errored = false
      end

      def around_perform_requests(requests)
        catch(:error) do
          yield requests
        end

        @responses
      end

      def around_perform_request(env)
        response = yield env
        @responses << response

        if error?(response)
          @errored = true
          throw :error
        end
      end

      def around_build_response(json_responses)
        batch_response = yield json_responses

        batch_response[0] = json_responses.last[:status] if @errored

        batch_response
      end

      private

      def error?(response)
        status, = response
        (status.to_i / 100) > 3 # considered an error if status is 4xx or 5xx
      end
    end
  end
end
