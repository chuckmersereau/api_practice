def create_empty_batch_request_with_params(params)
  json_body = {
    requests: []
  }.merge(params)
  request_body = JSON.dump(json_body)
  env = Rack::MockRequest.env_for('/api/v2/batch', method: 'POST', input: request_body)

  BatchRequestHandler::BatchRequest.new(env)
end
