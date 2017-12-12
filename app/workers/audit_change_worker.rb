class AuditChangeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_audit_change_worker, unique: :until_executed

  def perform(attrs)
    send_audit_to_elastic(attrs)
  end

  private

  def send_audit_to_elastic(attrs)
    # ensure the needed index is there
    Audited::AuditElastic.gateway.create_index!

    Audited::AuditElastic.create(attrs)
  end
end
