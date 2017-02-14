require 'json_api_service/configuration'
require 'json_api_service/errors'
require 'json_api_service/validator'
require 'json_api_service/transformer'
require 'json_api_service/params_object'

module JsonApiService
  class << self
    attr_writer :configuration
  end

  def self.consume(params:, context:)
    Validator.validate!(
      params: params,
      context: context,
      configuration: configuration
    )

    Transformer.transform(
      params: params,
      configuration: configuration
    )
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(value)
    @configuration = value
  end

  def self.configure
    yield(configuration)
  end
end
