if Rails.env.production? || Rails.env.staging?
  Rails.configuration.datadog_trace = {
    enabled: true,
    auto_instrument: true,
    auto_instrument_redis: true,
    auto_instrument_grape: false,
    default_service: Rails.env.production? ? 'mpdx_api' : 'mpdx_api_staging',
    default_controller_service: Rails.env.production? ? 'mpdx_api-controller' : 'mpdx_api_staging-controller',
    default_cache_service: 'rails-cache',
    default_database_service: Rails.env.production? ? 'mpdx (next)' : 'mpdx_staging (next)',
    template_base_path: 'views/',
    tracer: Datadog.tracer,
    debug: false,
    trace_agent_hostname: 'datadog-apm.aws.cru.org',
    trace_agent_port: 8126,
    env: Rails.env,
    tags: {app: Rails.env.production? ? 'mpdx_api' : 'mpdx_api_staging' }
  }
else
  Rails.configuration.datadog_trace = {
    enabled: false
  }
end
