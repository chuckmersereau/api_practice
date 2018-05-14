module GmailComposeLinkHelper
  def link_to_gmail_compose(name, opts = {})
    gmail_opts = [:to, :subject, :body, :cc, :bcc]
    link_to(name, gmail_compose_url(opts.slice(*gmail_opts)), opts.except(*gmail_opts))
  end

  private

  # See: https://stackoverflow.com/q/6548570/879524
  def gmail_compose_url(opts = {})
    options = { view: 'cm', fs: 1, to: opts[:to], su: opts[:subject],
                body: opts[:body], bcc: opts[:bcc], cc: opts[:cc] }
    params = options.select { |_, v| v.present? }.to_param
    "https://mail.google.com/mail/?#{params}"
  end
end
