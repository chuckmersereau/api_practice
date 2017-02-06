# This is a monkey patch that changes the format of the Rails default error response body.
#
# When responding to a JSON format request, Rails will by default send errors formatted like:
#
#   {
#     "status": "404",
#     "error": "Not Found"
#   }
#
# We want Rails to conform to JSON:API spec, so the error response should look like this:
#
#   {
#     "errors": [
#       {
#         "status": "404",
#         "title": "Not Found"
#       }
#     ]
#   }
#
# This monkey patch achieves this by altering the behaviour of the ActionDispatch middleware
# to format the body using our ErrorSerializer.
#
# This is handled at the middleware level so that all exceptions will return the correct format,
# not just those inside the Rails app.
#
# (This could also be handled by creating a custom exceptions_app, but the patch was simpler)

module ActionDispatch
  class PublicExceptions
    private

    alias_method :original_render, :render

    def render(status, content_type, body)
      error_serializer = ErrorSerializer.new(
        title: body[:error],
        status: status
      )
      original_render(status, content_type, error_serializer.as_json)
    end
  end
end
