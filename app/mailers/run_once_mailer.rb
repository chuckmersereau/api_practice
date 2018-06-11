# here's a great place
class RunOnceMailer < ApplicationMailer
  layout 'inky', except: :gdpr_unsubscribes

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

  def gdpr_unsubscribes(to, account_list_name, unsubscribe_details)
    @account_list_name = account_list_name
    @unsubscribe = unsubscribe_details
    @url = WebRouter.person_url(Person.find(@unsubscribe[:person_id]), Contact.find(@unsubscribe[:contact_id]))

    mail to: to, from: 'Paul Alexander <paul.alexander@cru.org>', reply_to: 'support@mpdx.org',
         subject: '[Action Required] Important Message About Some Of Your MPDX Contacts'
  end
end
