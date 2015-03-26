module JobDuplicateChecker
  def duplicate_job?(*args)
    job_in_retries?(args) || older_job_running?(args)
  end

  private

  def older_job_running?(args)
    workers = Sidekiq::Workers.new
    self_worker = workers.find { |_, _, work| work['payload']['jid'] == jid }
    return if self_worker.nil?
    self_work = self_worker.third
    self_run_at = self_work['run_at'].to_i
    self_enqueued_at = self_work['payload']['enqueued_at'].to_f

    workers.any? do |_process_id, _thread_id, work|
      job = work['payload']
      run_at = work['run_at'].to_i
      enqueued_at = job['enqueued_at'].to_f

      job['class'] == self.class.name && job['args'] == args &&
        (run_at < self_run_at || (run_at == self_run_at && enqueued_at < self_enqueued_at))
    end
  end

  def job_in_retries?(args)
    Sidekiq::RetrySet.new.any? { |retri| retri.klass == self.class.name && retri.args == args }
  end
end
