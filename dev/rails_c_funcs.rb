load('./dev/address_history.rb')

def fix_donation_totals(account_list)
  account_list = account_list.id unless account_list.blank? || account_list.is_a?(Integer)
  sql = '
  UPDATE contacts
  SET total_donations = correct_totals.total
  FROM (
    SELECT contacts.id contact_id, SUM(donations.amount) total
    FROM contacts, contact_donor_accounts, account_list_entries, donations
    WHERE contacts.id = contact_donor_accounts.contact_id
    AND donations.donor_account_id = contact_donor_accounts.donor_account_id
    AND contacts.account_list_id = account_list_entries.account_list_id ' +
        (account_list ? "AND account_list_entries.account_list_id = #{account_list}" : '') +
        ' AND donations.designation_account_id = account_list_entries.designation_account_id
    GROUP BY contacts.id
    ) correct_totals
  WHERE correct_totals.contact_id = contacts.id
  '
  Donation.connection.execute(sql)
end

def schedule_sync(mc_account, index)
  id = mc_account.id
  num_secs = index * 60
  MailChimpAccount.perform_in(num_secs.seconds, id, :call_mailchimp, :export_to_primary_list)
end

def backup_mc_account(mc_account)
  puts mc_account.id
  json = {
    account_list: mc_account.account_list,
    members: mc_account.list_members(mc_account.primary_list_id)
  }.to_json
  filename = "mc_backup/#{mc_account.id}.json"
  File.open(filename, 'w') { |file| file.write(json) }
rescue => e
  puts e
end

def weed_queues
  q = Sidekiq::Queue.new('import')
  q.each do |job|
    next unless
      (job.klass == 'AccountList' &&
       (job.args[1] == 'import_data' || job.args[2] == 'sync_with_google_contacts')
      ) ||
      (job.klass == 'LowerRetryWorker' && job.args[2] == 'sync_data' && job.args[3] == 'email')

    puts job.args
    puts job.delete
  end
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

def enqueue_all_reliability
  enqueue_reliability('default')
  enqueue_reliability('import')
end

def clear_reliability(q = 'default')
  r = Redis.current
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    r.ltrim(reliability_q, -1, 0)
  end
end

def reliability_items(q = 'default')
  r = Redis.current
  qs = r.keys("resque:queue:#{q}_*")
  qs.each do |reliability_q|
    puts r.lrange(reliability_q, 0, -1).inspect
  end
end

def make_single_addresses_primary(a)
  a.contacts.each(&method(:fix_missing_primary))
end

def fix_missing_primary(c)
  primary_addr = c.addresses.where(primary_mailing_address: true)
  return if primary_addr.any?

  addrs = c.addresses.where.not(historic: true)
  if addrs.count == 1
    puts "Setting primary address for #{c} to #{addrs.first.id}"
    addrs.first.update!(primary_mailing_address: true)
  end
end

def add_dev_user(account_list)
  dev_user.account_list_users.create(account_list: account_list)
end

def dev_user_back_to_normal
  dev_user.account_list_users.select do |alu|
    alu.account_list != dev_account
  end.map(&:destroy)
end

def dev_user(id = nil)
  id ||= ENV['DEV_USER_ID']
  return @dev_user if @dev_user || id.blank?
  @dev_user = User.find_by(id: id)
  PaperTrail.whodunnit = @dev_user
end

def dev_account(id = nil)
  id ||= ENV['DEV_ACCOUNT_LIST_ID']
  @dev_account ||= AccountList.find_by(id: id)
end

def find_a(name)
  first, last = name.split(' ')
  alus = AccountListUser.joins(:user).where(people: { first_name: first, last_name: last })
  puts alus.count
  if alus.count == 1
    alus.first.account_list
  else
    alus.map(&:account_list)
  end
end

def find_a_by_e(email)
  alus = AccountListUser.joins(:user) \
         .joins('inner join email_addresses on email_addresses.person_id = people.id') \
         .where(email_addresses: { email: email })
  puts alus.count
  if alus.count == 1
    alus.first.account_list
  else
    alus.map(&:account_list)
  end
end

class DummyContext
  def number_to_current_currency(x)
    "$#{x}"
  end
end
def balance(a, u)
  e = AccountListExhibit.new(a, DummyContext.new)
  e.balances(u)
end

def log_active_record
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  # ActiveRecord::Base.logger.level = 1
end

def add_offline_org(org_name, website = 'example.com')
  Organization.create(name: org_name, api_class: 'OfflineOrg', query_ini_url: website, addresses_url: 'example.com')
end

def save_account_list_sql_to_s3(account_list)
  filename = "account_list_#{account_list.id}_at_#{Time.now.to_i}.sql"
  upload_to_s3(filename, account_list_sql(account_list))
end

def upload_to_s3(filename, body)
  conn = Fog::Storage.new(provider: 'AWS',
                          aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
                          aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
  dir = conn.directories.get(ENV.fetch('AWS_BUCKET'))
  path = "debug_exports/#{filename}"
  file = dir.files.new(key: path, body: body)
  file.save
  puts "Saved in #{ENV.fetch('AWS_BUCKET')} bucket at #{path}"
end

def account_list_sql(account_list)
  sql = []
  sql << model_insert_sql(account_list)
  [
    account_list.contacts,
    account_list.people,
    account_list.addresses,
    ContactPerson.where(contact: account_list.contacts),
    PhoneNumber.where(person: account_list.people),
    EmailAddress.where(person: account_list.people)
  ].each do |relation|
    sql += relation_insert_sql(relation)
  end
  sql.join("\n")
end

def relation_insert_sql(relation)
  relation.uniq.map(&method(:model_insert_sql))
end

def model_insert_sql(model)
  quoted_columns = []
  quoted_values = []

  attributes_with_values =
    model.send(:arel_attributes_with_values_for_create, model.attribute_names)

  attributes_with_values.each_pair do |key, value|
    quoted_columns << ActiveRecord::Base.connection.quote_column_name(key.name)
    quoted_values << ActiveRecord::Base.connection.quote(value)
  end

  "INSERT INTO #{model.class.quoted_table_name} (#{quoted_columns.join(', ')}) VALUES (#{quoted_values.join(', ')});\n"
end
