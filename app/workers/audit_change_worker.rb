class AuditChangeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_audit_change_worker, unique: :until_executed

  def perform(attrs)
    send_audit_to_elastic(attrs)
  end

  private

  def send_audit_to_elastic(attrs)
    ensure_index

    Audited::AuditElastic.create(attrs)
  end

  def ensure_index
    # ensure the needed index is there
    Audited::AuditElastic.gateway.create_index!
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
    # catch race condition where index already exists and it got past the internal `index_exists?`
    raise e unless e.message.include? 'index_already_exists_exception'
  end
end
