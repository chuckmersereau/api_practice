class MonitorsController < ActionController::API
  def lb
    ActiveRecord::Migration.check_pending!
    ActiveRecord::Base.connection.select_values('select id from people limit 1')
    render text: File.read(Rails.public_path.join('lb.txt'))
  rescue ActiveRecord::PendingMigrationError
    render text: 'PENDING MIGRATIONS', status: :service_unavailable
  end

  def sidekiq
    if SidekiqMonitor.queue_latency_too_high?
      render text: 'Queue latency too high', status: :internal_server_error
    else
      render text: 'OK'
    end
  end

  def commit
    render text: ENV['GIT_COMMIT']
  end
end
