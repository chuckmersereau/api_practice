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
