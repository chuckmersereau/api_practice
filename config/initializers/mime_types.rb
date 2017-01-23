# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# Adds the JSONAPI Spec media type:
# http://jsonapi.org/format/#introduction
# http://jsonapi.org/format/#content-negotiation
#
# Solution: https://github.com/rails-api/active_model_serializers/issues/1027#issuecomment-126543577
api_mime_types = %w(
  application/vnd.api+json
  text/x-json
  application/json
)

Mime::Type.unregister :json
Mime::Type.register 'application/vnd.api+json', :json, api_mime_types

# For csv and xlsx exports
Mime::Type.register "text/csv", :csv
Mime::Type.register "application/xlsx", :xlsx
