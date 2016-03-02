# The fix parameter should be in underscore format e.g. account_dup_phones, but
# it will correspond to an admin fixer class, i.e. Admin::AccountDupPhonesFix
def schedule_admin_fixes(fix, time_period)
  count = AccountList.count
  interval = time_period / count
  Sidekiq.redis do |conn|
    conn.pipelined { schedule_fixes_at_intervals(fix, interval) }
  end
end

def schedule_fixes_at_intervals(fix, interval)
  AccountList.pluck(:id).sort.each_with_index do |account_list_id, index|
    Admin::FixWorker.perform_in(interval * index, fix,
                                'AccountList', account_list_id)
  end
end

def schedule_dup_phone_fixes
  schedule_admin_fixes('account_dup_phones', 48.hours)
end

def schedule_primary_address_fixes
  schedule_admin_fixes('account_primary_addresses', 24.hours)
end
