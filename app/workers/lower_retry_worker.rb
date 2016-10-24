class LowerRetryWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed

  sidekiq_retry_in do |count|
    count**6 + 30 # 30, 31, 94, 759, 4126 ... second delays
  end

  def perform(klass_str, id, method, *args)
    if id
      begin
        klass_str.constantize.find(id).send(method, *args)
      rescue ActiveRecord::RecordNotFound
        # If this instance has been deleted, oh well.
      end
    else
      send(method, *args)
    end
  end

  class RetryJobButNoRollbarError < StandardError
  end
end
