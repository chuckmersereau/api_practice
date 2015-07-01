module GmailComposeLinkHelper
  def link_to_gmail_compose(name, opts = {})
    gmail_opts = [:to, :subject, :body, :cc, :bcc]
    link_to(name, gmail_compose_url(opts.slice(*gmail_opts)), opts.except(*gmail_opts))
  end

  private

  # See: http://stackoverflow.com/questions/6548570/url-to-compose-a-message-in-gmail-with-full-gmail-interface-and-specified-to-b
  def gmail_compose_url(opts = {})
    "https://mail.google.com/mail/?#{{ view: 'cm', fs: 1, to: opts[:to], su: opts[:subject], body: opts[:body], bcc: opts[:bcc], cc: opts[:cc] }
      .select { |_, v| v.present? }.to_param}"
  end
end
