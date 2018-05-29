# inspired by: https://gist.github.com/dennisfaust/c94f0e1aec54e37c52e431e9542ff042
# because of: https://github.com/mhenrixon/sidekiq-unique-jobs/issues/234
class RedisHashCompactorWorker
  include Sidekiq::Worker

  PER_PAGE = 1_000

  # we normally don't put things in this queue because it is only run by one legacy worker (we had one
  # queue reserved for mpdx classic that we haven't repurposed yet), but it seems logical to use it for this.
  sidekiq_options queue: :default

  def perform
    # We need this to get a redis connection with no namespace gem
    @conn = Redis.new(host: Redis.current.client.host, port: Redis.current.client.port)

    cursor = '0'
    loop do
      cursor = scan_from(cursor)
      break if cursor == '0'
    end
  end

  private

  def scan_from(start_cursor)
    cursor, jobs = @conn.hscan(SidekiqUniqueJobs::HASH_KEY, [start_cursor, 'MATCH', '*', 'COUNT', PER_PAGE])

    to_delete = jobs.map do |jid, unique_key|
      # don't delete if job is still waiting to run
      jid unless @conn.exists(unique_key)
    end.compact
    @conn.hdel(SidekiqUniqueJobs::HASH_KEY, to_delete) if to_delete.any?
    cursor
  end
end
