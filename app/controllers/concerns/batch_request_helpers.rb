module BatchRequestHelpers
  private

  def reject_if_in_batch_request
    if request.env['BATCH_REQUEST']
      error = BatchRequestHandler::Instruments::RequestValidator::InvalidBatchRequestError.new(
        status: 403,
        message: 'You cannot access this endpoint from within a batch request'
      )
      rack_request = Rack::Request.new(request.env)
      json_payload = BatchRequestHandler::Instruments::RequestValidator.generate_invalid_batch_request_json_payload(error, rack_request)

      render json: json_payload, status: 403
    end
  end
end
