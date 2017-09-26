class GooglePlusAccountFetcherWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_plus_account_fetcher_worker, unique: :until_executed

  def perform(email_address_id)
    email_address = EmailAddress.find_by(id: email_address_id)

    return unless email_address

    google_plus_account = fetch_google_plus_account_from_email_address(email_address)

    email_address.update(checked_for_google_plus_account: true)

    email_address.google_plus_account = google_plus_account
  end

  private

  def fetch_google_plus_account_from_email_address(email_address)
    EmailAddress::GooglePlusAccountFetcher.new(email_address).fetch_google_plus_account
  end
end
