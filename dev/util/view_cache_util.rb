# Helpful for expiring an account's donations chart if there has been a recent
# update in their donations and they don't know why the chart isn't updating.
# (Or if you did a change to a test account for purpose of training videos.)
def expire_donations_chart(account_list)
  r = view_cache_redis
  prefix = 'cache:views/donations_summary_chart/account_lists'
  # the full key has some extra numbers after the id
  wildcard_key = "#{prefix}/#{account_list.id}*"
  full_key = r.keys(wildcard_key).first
  r.del(full_key)
end

def view_cache_redis
  view_cache_db = 1
  client = Redis.new(host: Redis.current.client.host,
                     port: Redis.current.client.port,
                     db: view_cache_db)
  Redis::Namespace.new(Redis.current.namespace, redis: client)
end
