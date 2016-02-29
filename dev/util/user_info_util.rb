def user_info(u)
  puts "Account Lists for user ##{u.id} #{u.first_name} #{u.last_name}"
  puts '-' * 20
  u.account_lists.each do |a|
    puts account_list_str(a)
    a.users.each do |a_u|
      puts '  ' + user_str(a_u)
      a_u.key_accounts.each do |ka|
        puts '    ' + key_account_str(ka)
      end
      a_u.relay_accounts.each do |ra|
        puts '    ' + relay_account_str(ra)
      end
    end
    a.designation_accounts.each do |da|
      puts '  ' + designation_account_str(da)
    end
    a.designation_profiles.each do |dp|
      puts '  ' + designation_profile_str(dp)
      dp.designation_accounts.each do |da|
        puts '    ' + designation_account_str(da)
      end
    end
  end
  true
end

def user_str(u)
  "user ##{u.id} #{u.first_name} #{u.last_name}"
end

def key_account_str(ka)
  "key #{ka.email}"
end

def relay_account_str(ra)
  "relay #{ra.username}"
end

def account_list_str(a)
  "#{a.name} ##{a.id}"
end

def designation_account_str(da)
  "desig ##{da.id} '#{da.name}' (#{da.designation_number}) $#{da.balance}"
end

def designation_profile_str(dp)
  "prof ##{dp.id} '#{dp.name}' (#{dp.code}) $#{dp.balance}"
end
