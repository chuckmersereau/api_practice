class SubscriberCleanedMailer < ApplicationMailer
  def subscriber_cleaned(account_list, cleaned_email)
    return unless account_list.users.first
    @email = cleaned_email
    @person = @email.person
    @contact = @person.contact
    user_emails = account_list.user_emails_with_names
    I18n.locale = account_list.users.first.locale || 'en'
    mail subject: _('MailChimp subscriber email bounced'), to: user_emails
  end
end
