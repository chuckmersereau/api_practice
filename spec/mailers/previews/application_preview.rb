class ApplicationPreview < ActionMailer::Preview
  def account_list
    @account_list ||= AccountList.where(name: 'Email Preview Account List').first_or_create
  end

  def user
    return @user if @user
    @user = User.where(first_name: 'Robert', last_name: 'Emailer').first_or_create
    @user.email = 'robert.emailer@cru.org' unless @user.email
    AccountListUser.where(user: @user, account_list: account_list).first_or_create
    @user
  end
end
