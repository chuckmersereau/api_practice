class SidekiqWhodunnit
  def call(_worker, job, _queue)
    PaperTrail.whodunnit = "#{job['class']} #{job['args'].inspect}"
    yield
  end
end
