module BatchRequestHandler
  # The Instrument class is used to add features or concerns to the
  # BatchRequest. It provides three life-cycle hooks that you may use to alter
  # or inspect the handling of the batch request.
  #
  # There is a class method, `enabled_for?`, which takes a BatchRequest as an
  # object and returns true or false if the instrument should be active for that
  # batch request.
  #
  # If the instrument does match the current BatchRequest, the instrument will
  # be instantiated with the params from the BatchRequest, and added to the
  # BatchRequest's list of instruments.
  #
  # While the BatchRequest is processing, it will call three different
  # life-cycle methods on the instrument objects it contains. Each life-cycle
  # method will receive some arguments and a block. The block is the next
  # instrument's same life-cycle method, or in the case of the final instrument,
  # the actual BatchRequest's life-cycle method. The life-cycle methods have the
  # important responsibility of passing along the arguments it was given, to the
  # next block. They also have the responsibility of returning a certain value.
  # The value they must return is the result of calling the block with the
  # necessary arguments.
  #
  # The power of the instrument comes from being able to modify the arguments
  # given to it, before it passes them along to the block. And likewise, being
  # able to make changes to the result of calling the block, and returning it's
  # own changes instead.
  #
  # Each life-cycle method has been documented with the arguments it receives,
  # what the block expects to be called with, what the block returns, and what
  # the method is supposed to return.
  #
  # Also note that instead of needing to explicitly define the block in the list
  # of arguments, we can simply use `yield` passing it the required arguments,
  # and that will be the same as calling the block with those arguments.
  class Instrument
    # Arguments:
    #   batch_request - the current BatchRequest object
    # Should return:
    #   a boolean, representing whether or not to use this instrument for the
    #   given batch request
    def self.enabled_for?(_batch_request)
      true
    end

    # Arguments:
    #   params - the params (all key => value pairs sent in the json body of the
    #            batch request except for `requests`)
    def initialize(_params)
    end

    # Arguments:
    #   requests - the array of request objects from the batch json payload
    #   block    - the given block expects to be called with the requests. When
    #              called with an array of requests, it will return an array of
    #              Rack responses
    # Should return:
    #   an array of Rack response objects
    def around_perform_requests(requests)
      yield requests
    end

    # Arguments:
    #   env   - the environment that will be passed down the middleware to
    #           perform the request. The environment may be mutated
    #   block - the given block expects to be called with the environment.
    #           Calling the block with the environment will continue down the
    #           middleware chain and will return a Rack response object
    # Should return:
    #   a Rack response object
    def around_perform_request(env)
      yield env
    end

    # Arguments:
    #   json_responses - an array of responses that have been formatted into a
    #                    Hash for JSON serialization
    #   block          - the given block expects to be called with an array of
    #                    Hash formatted responses. It returns a Rack response
    #                    which will be used as the response for the batch request
    # Should return:
    #   a Rack response object
    def around_build_response(json_responses)
      yield json_responses
    end
  end
end
