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
