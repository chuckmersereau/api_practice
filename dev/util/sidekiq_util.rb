# In addition to the normal work queues that Sidekiq has, Sidekiq Pro has a
# reliability queue for each of the sidekiq processes.
#
# The contents of that queue aren't shown on the Sidekiq web dashboard, but
# typically it will match whatever jobs that sidekiq process is running.
#
# Several of these methods help deal with the reliability queue.

# Removes certain jobs from the reliability queues for a certain sidekiq queue
# This can be useful if you want to cancel a certain type of job. Just
# restarting sidekiq would restart those jobs so you need to yank them from the
# reliability queues first then restart sidekiq.
def remove_from_reliability(q = 'default', &_block)
  r = Redis.current
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    list = r.lrange(reliability_q, 0, -1)
    list.each do |item|
      json = JSON.parse(item)
      r.lrem(reliability_q, 1, item) if yield(json)
    end
  end
end

# Useful for clear out Gmail sync jobs when Sidekiq is too busy
def remove_google_integration
  remove_from_reliability do |item|
    item['class'] == 'GoogleIntegration'
  end
end

# Get items in the reliability queue
def reliability_items(q = 'default')
  r = Redis.current
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    puts r.lrange(reliability_q, 0, -1).inspect
  end
end

# This can be helpful if e.g. the process index of sidekiq changed or you
# reduced the number of sidekiq processes and you want to capture all of the
# jobs those processes were running.
def enqueue_all_reliability
  enqueue_reliability('default')
  enqueue_reliability('import')
end

# Move all reliability queues to the default queue
def enqueue_reliability(q)
  r = Redis.current
  running_hosts = Sidekiq::ProcessSet.new.map { |p| p['hostname'] }
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    next if running_hosts.any? { |h| reliability_q.include?(h) }
    len = r.llen(reliability_q)
    r.pipelined do
      len.times { r.rpoplpush(reliability_q, "resque:queue:#{q}") }
    end
  end
end

# Be careful with this as it will remove all jobs from the reliability queues
# which means that once you restart sidekiq jobs may never get run. Better to
# yank specific jobs or job types from the reliability queue.
def clear_reliability(q = 'default')
  r = Redis.current
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    r.ltrim(reliability_q, -1, 0)
  end
end

def remove_enqueued_account_list_imports
  q = Sidekiq::Queue.new('import')
  q.each do |job|
    next unless job.klass == 'AccountList' && (job.args[1] == 'import_data')
    puts job.delete
  end
end

# Be careful in using this method: it will clear all of the uniqueness
# locks for Sidekiq jobs which can result in duplicate jobs running. It is
# useful in cases though when there are incorrect uniqueness locks set for a
# particular job and you want to clear them all to start over.
# What you should probably do first is make sure the currently running Sidekiq
# jobs finish (or clear the reliability queue, clear out donor imports from the
# import queue and re-promote the build to restart Sidekiq).
def clear_uniqueness_locks
  r = Redis.current
  uniqueness_locks = r.keys('resque:sidekiq_unique:*')
  r.pipelined { uniqueness_locks.each { |k| r.del(k) } }
end

# Removes items from the Sidekiq retry list. For selectively removing large
# numbers of items this is much faster than the Sidekiq::RetrySet.new approach
# since that would involve one Redis call per removed item vs. this method that
# does it pipelined.
# As an example, here's how to remove 40K mailchimp retry jobs with it while
# keeping any other jobs the system is retrying still in the queue:
# 40.times do
#  remove_selected_from_retry_set(1000) do |item|
#    item[:class] == 'MailChimpAccount'
#  end
# end
def remove_selected_from_retry_set(count = 1000)
  retry_q = 'resque:retry'
  r = Redis.current
  items = r.zrange(retry_q, 0, count)

  kept = 0
  removed = 0
  r.pipelined do
    items.each do |item_json|
      item = JSON.parse(item_json).with_indifferent_access
      if yield(item)
        r.zrem(retry_q, item_json)
        removed += 1
      else
        kept += 1
      end
    end
  end

  puts "Removed #{removed} items, kept #{kept} items"
end
