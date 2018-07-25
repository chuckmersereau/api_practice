class MailChimpMailer < ApplicationMailer
  layout 'inky'

  def invalid_email_addresses(account_list, user, emails_with_person_ids)
    @account_list = account_list
    @user = user
    @emails_with_people = emails_with_person_ids.transform_values do |person_ids|
      @account_list.people.where(id: person_ids)
    end
    mail to: user.email_address,
         subject: _('MPDX was unable to sync some email addresses to MailChimp')
  end
end
