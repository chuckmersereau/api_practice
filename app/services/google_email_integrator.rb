class GoogleEmailIntegrator
  attr_accessor :client

  def initialize(google_integration)
    @google_integration = google_integration
    @google_account = google_integration.google_account
  end

  def sync_data
    return unless @google_integration.email_integration?
    gmail_account = Person::GmailAccount.new(@google_account)
    gmail_account.import_emails(@google_integration.account_list, @google_integration.email_blacklist)
  end
  alias sync_mail sync_data
end
