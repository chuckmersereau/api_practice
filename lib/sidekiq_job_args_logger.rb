class SidekiqJobArgsLogger
  def call(_worker, job, _queue)
    # class, jid and enqueued_at are implied by the logger header
    Sidekiq.logger.info { job.except('class', 'jid', 'enqueued_at') }
    yield
  end
end
