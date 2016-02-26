class MonitorsController < ApplicationController
  skip_before_action :ensure_login
  skip_before_action :ensure_setup_finished
  layout nil
  newrelic_ignore

  def lb
    ActiveRecord::Base.connection.select_values('select id from people limit 1')
    render text: File.read(Rails.public_path.join('lb.txt'))
  end

  def sidekiq
    if SidekiqMonitor.queue_latency_too_high?
      render text: 'Queue latency too high', status: :internal_server_error
    else
      render text: 'OK'
    end
  end
end
