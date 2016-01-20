require 'spec_helper'

describe GoogleEmailIntegrator, '#sync_mail' do
  it 'imports emails if email integration enable' do
    integration = build_google_integration(true)
    integrator = GoogleEmailIntegrator.new(integration)
    gmail_account = double
    expect(Person::GmailAccount).to receive(:new) { gmail_account }
    expect(gmail_account).to receive(:import_emails)
      .with(integration.account_list)
    integrator.sync_mail
  end

  it 'does not import emails if integration not enabled' do
    integrator = GoogleEmailIntegrator.new(build_google_integration(false))
    expect(Person::GmailAccount).to_not receive(:new)
    integrator.sync_mail
  end

  def build_google_integration(email_integration)
    account_list = build(:account_list)
    build(:google_integration, email_integration: email_integration,
                               account_list: account_list)
  end
end
