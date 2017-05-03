module BatchRequestHandler
  class BatchRequest
    InvalidBatchRequestError = Class.new(StandardError)
    attr_reader :requests, :params

    def initialize(env)
      request_body = parse_batch_request_object(env)

      @env         = env
      @requests    = request_body.fetch('requests')
      @params      = request_body.except('requests').freeze
      @instruments = []
      @responses   = []
    rescue KeyError, JSON::ParserError
      raise InvalidBatchRequestError
    end

    def add_instrumentation(instrument_class)
      if instrument_class.enabled_for?(self)
        @instruments << instrument_class.new(@params)
      end
    end

    def process(app)
      perform_requests!(app)
      build_response!
    end

    private

    def perform_requests!(app)
      @responses = instrument(:around_perform_requests, @requests) do |requests|
        requests.map do |request|
          perform_request!(app, request)
        end
      end
    end

    def perform_request!(app, request)
      new_env = build_env_for_request(@env, request)

      instrument(:around_perform_request, new_env) do |instrumented_env|
        app.call(instrumented_env)
      end
    end

    def build_response!
      json_responses = @responses.map { |response| response_to_json(response) }

      instrument(:around_build_response, json_responses) do |json|
        response_body = JSON.dump(json)

        [200, { 'Content-Type' => 'application/json' }, [response_body]]
      end
    end

    # `instrument` is responsible for making sure that all of the
    # instrumentation classes get called. It takes the method name to call on
    # the instrument class, the arguments to pass to the method, and the block.
    # It reduces all of the instruments methods into a nested proc.
    def instrument(method, *yielded_arguments, &block)
      instrumented_block = @instruments.reverse.reduce(block) do |inner_block, instrument|
        -> (*yielded_args) { instrument.send(method, *yielded_args, &inner_block) }
      end

      instrumented_block.call(*yielded_arguments)
    end

    def parse_batch_request_object(env)
      body = env['rack.input'].read

      JSON.parse(body)
    end

    def build_env_for_request(env, request)
      body = request.fetch('body', '')
      body = coerce_body_to_string(body)

      env.deep_dup.tap do |new_env|
        new_env['BATCH_REQUEST']  = true
        new_env['REQUEST_METHOD'] = request['method']
        new_env['PATH_INFO']      = request['path']
        new_env['CONTENT_LENGTH'] = body.bytesize
        new_env['rack.input']     = StringIO.new(body)
      end
    end

    def coerce_body_to_string(body)
      case body
      when String then body
      else
        JSON.dump(body)
      end
    end

    def response_to_json(response)
      status, headers, body_proxy = response

      body = ''
      body_proxy.each { |chunk| body << chunk }
      body_proxy.close if body_proxy.respond_to?(:close)

      {
        status: status,
        headers: headers,
        body: body
      }
    end
  end
end
