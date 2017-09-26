require 'rails_helper'

RSpec.describe GooglePlusAccountFetcherWorker do
  context '#perform' do
    let(:email_address) { create(:email_address) }
    let(:mock_google_plus_account_fetcher) { double(:mock_google_plus_account_fetcher) }

    it 'fetches the google plus account and marks the email_address as checked_for_google_account' do
      expect(EmailAddress::GooglePlusAccountFetcher).to receive(:new).with(email_address).and_return(mock_google_plus_account_fetcher)
      expect(mock_google_plus_account_fetcher).to receive(:fetch_google_plus_account).and_return(build(:google_plus_account))

      described_class.new.perform(email_address.id)
      expect(email_address.reload.checked_for_google_plus_account).to be_truthy
      expect(email_address.google_plus_account.reload).to be_present
    end

    it 'returns nil if the EmailAddress Id doesnt exist' do
      expect(described_class.new.perform(10_000)).to be_nil
    end
  end
end
