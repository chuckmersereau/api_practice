class SidekiqAuditedUser
  def call(_worker, job, _queue)
    klass = job['class'].is_a?(String) ? job['class'].constantize : job['class']
    ::Audited.store[:audited_user] = klass.new
    yield
  end
end
