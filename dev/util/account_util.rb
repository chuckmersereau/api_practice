def find_u(id_name_or_email)
  users = Admin::UserFinder.find_users(id_name_or_email)
  if users.count <= 1
    users.first
  elsif users.count > 1
    puts 'multiple users'
    users
  end
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

def remove_account_list(user, account_list)
  account_list.account_list_users.find_by(user: user).destroy
  account_list.account_list_users.find_by(user: user)
end
