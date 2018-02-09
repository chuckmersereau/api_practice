class BackgroundBatch::RequestWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_background_batch_request, unique: :until_executed, retry: true

  def perform(id)
    @request = BackgroundBatch::Request.find_by!(id: id)
    load_response if @request
  end

  protected

  def load_response
    RestClient::Request.execute(request_params) do |response|
      update_request(response)
    end
  end

  def request_params
    {
      method: @request.request_method,
      payload: @request.request_body,
      url: @request.formatted_path,
      headers: @request.formatted_request_headers,
      timeout: nil
    }
  end

  def update_request(response)
    @request.update(
      response_body: response.body,
      response_headers: response.headers,
      response_status: response.code,
      status: 'complete'
    )
  end
end
