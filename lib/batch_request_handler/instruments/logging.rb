module BatchRequestHandler
  module Instruments
    class Logging < BatchRequestHandler::Instrument
      def initialize(_params)
        @request_index = 0
      end

      def around_perform_requests(requests)
        @request_count = requests.length
        yield requests
      end

      def around_perform_request(env)
        rack_request = Rack::Request.new(env)
        @request_index += 1
        Rails.logger.info("Started #{rack_request.request_method} \"#{rack_request.path}\" as part of batch (#{@request_index}/#{@request_count}) for #{rack_request.ip} at #{Time.now}")
        yield env
      end
    end
  end
end
