require 'global_registry'
require 'global_registry_bindings'
GlobalRegistry.configure do |config|
  config.access_token = ENV.fetch('GLOBAL_REGISTRY_TOKEN') { 'fake' }
  config.base_url = ENV.fetch('GLOBAL_REGISTRY_URL') { 'https://backend.global-registry.org' }
end

GlobalRegistry::Bindings.configure do |config|
  config.sidekiq_options = { queue: :api_global_registry_bindings }
end
