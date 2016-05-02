class HelpRequestMailer < ActionMailer::Base
  default from: 'support@mpdx.org'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.help_request_mailer.email.subject
  #
  def email(help_request)
    @help_request = help_request
    @attachment_url = attachment_url(help_request.id) if help_request.file?

    from = if help_request.email.include?('cru.org')
             "#{help_request.name} <#{help_request.email}>"
           else
             'support@mpdx.org'
           end

    mail to: 'support@mpdx.org', subject: help_request.request_type,
         from: from, reply_to: "#{help_request.name} <#{help_request.email}>"
  end

  def attachment_url(help_request_id)
    attachment_help_request_url(HelpRequest.attachment_token(help_request_id))
  end
end
