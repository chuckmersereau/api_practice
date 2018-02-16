# here's a great place
class RunOnceMailer < ApplicationMailer
  layout 'inky'

  def fix_newsletter_status(emails, fixed_count, account_list_name)
    @fixed_count = fixed_count
    @account_list_name = account_list_name
    mail to: emails, subject: 'MPDX - Mailchimp Bug Update'
  end

  def new_mailchimp_list(emails, fixed_count, account_list_name, mc_list_url)
    @fixed_count = fixed_count
    @account_list_name = account_list_name
    @mc_list_url = mc_list_url
    mail to: emails, subject: 'MPDX - Mailchimp Bug Update'
  end
end
