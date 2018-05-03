base_name = ENV['PROJECT_NAME']
enabled = ENV['DATADOG_TRACE'].to_s == 'true'

Datadog.configure do |c|
  # Tracer
  c.tracer hostname: 'datadog-apm.aws.cru.org',
           port: 8126,
           tags: { app: base_name },
           debug: false,
           enabled: enabled,
           env: Rails.env

  # Rails
  c.use :rails,
        service_name: base_name,
        controller_service: "#{base_name}-controller",
        cache_service: "#{base_name}-cache",
        database_service: "#{base_name}-db"

  # Redis
  c.use :redis, service_name: "#{base_name}-redis"

  # Sidekiq
  c.use :sidekiq, service_name: "#{base_name}-sidekiq"

  # Net::HTTP
  c.use :http, service_name: "#{base_name}-http"
end

# skipping the health check: if it returns true, the trace is dropped
Datadog::Pipeline.before_flush(Datadog::Pipeline::SpanFilter.new do |span|
  span.name == 'rack.request' && span.get_tag('http.url') == '/monitors/lb'
end)
