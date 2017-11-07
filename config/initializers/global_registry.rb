require 'global_registry'
require 'global_registry_bindings'
GlobalRegistry.configure do |config|
  config.access_token = ENV.fetch('GLOBAL_REGISTRY_TOKEN') { 'fake' }
  config.base_url = ENV.fetch('GLOBAL_REGISTRY_URL') { 'https://backend.global-registry.org' }
end

GlobalRegistry::Bindings.configure do |config|
  config.sidekiq_options = { queue: :api_global_registry_bindings }
end

unless ENV['ENABLE_GR_BINDINGS'] == 'true'
  module GlobalRegistry
    module Bindings
      class Worker
        class << self
          def perform_async(*_args)
          end
        end
      end
    end
  end
end
