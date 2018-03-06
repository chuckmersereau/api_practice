class AccountMailerPreview < ApplicationPreview
  def invalid_mailchimp_key
    AccountMailer.invalid_mailchimp_key(account_list)
  end

  def mailchimp_required_merge_field
    AccountMailer.mailchimp_required_merge_field(account_list)
  end

  def prayer_letters_invalid_token
    AccountMailer.prayer_letters_invalid_token(account_list)
  end

  private

  def account_list
    account_list = AccountList.new(name: 'Test Account')
    user = User.new(first_name: 'Bill', last_name: 'Bright')
    account_list.users << user
    user.email_addresses << EmailAddress.new(email: 'bill.bright@cru.org')
    account_list
  end
end
