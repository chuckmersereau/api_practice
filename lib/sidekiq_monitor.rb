module SidekiqMonitor
  def notify_if_problem
    problem = sidekiq_problem
    return unless problem

    ActionMailer::Base.mail(from: 'support@mpdx.org', to: config(:emails), subject: 'Sidekiq problem',
                            body: "#{problem}\r\n\r\nSee https://mpdx.org/sidekiq").deliver_now
  end

  def sidekiq_problem
    stats = Sidekiq::Stats.new
    procs = Sidekiq::ProcessSet.new
    threads = procs.map { |p| p['concurrency'].to_i }.reduce(0, :+)
    threads_free = threads - stats.workers_size

    if too_few_procs?(procs)
      sleep(config(:min_procs_interval).to_f)
      "Expected #{config(:min_procs)} processes but only #{procs.size} running" if too_few_procs?(procs)
    elsif stuck?(threads_free, stats)
      sleep(config(:stuck_interval).to_f)
      "Stuck: #{threads_free} threads free, but #{stats.enqueued} jobs enqueued" if stuck?(threads_free, stats)
    end
  end

  def too_few_procs?(processes)
    processes.size < config(:min_procs).to_i
  end

  def stuck?(threads_free, stats)
    threads_free > config(:stuck_threads_free).to_i && stats.enqueued > config(:stuck_enqueued).to_i
  end

  def config(key)
    ENV["sidekiq_warn_#{key}".upcase]
  end

  module_function :notify_if_problem, :sidekiq_problem, :config, :stuck?, :too_few_procs?
end
