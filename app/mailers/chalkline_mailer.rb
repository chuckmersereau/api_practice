class ChalklineMailer < ApplicationMailer
  TIME_ZONE = 'Central Time (US & Canada)'.freeze
  default to: ENV.fetch('CHALKLINE_NEWSLETTER_EMAIL')

  def mailing_list(account_list)
    @name = account_list.users_combined_name
    user_emails = account_list.user_emails_with_names
    time_formatted = Time.now.in_time_zone(TIME_ZONE).strftime('%Y%m%d %l%M%P')
    filename = "#{@name} #{time_formatted}.csv".gsub(/\s+/, '_').downcase
    attachments[filename] =
      { mime_type: 'text/csv',
        content: CsvExport.mailing_addresses(
          ContactFilter.new(newsletter: 'address').filter(account_list.contacts, account_list)
        ) }
    mail subject: format(_('MPDX List: %{name}'), name: @name), cc: user_emails, reply_to: user_emails
  end
end
