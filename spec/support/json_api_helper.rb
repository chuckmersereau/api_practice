module JsonApiHelper
  def json_response
    @json_response ||= JSON.parse(response_body)
  end
end
