require 'rails_helper'

RSpec.describe EmailAddress::GooglePlusAccountFetcher do
  context '#fetch_google_plus_account' do
    before do
      stub_request(:get, "https://picasaweb.google.com/data/entry/api/user/#{email_address.email}?alt=json")
        .to_return(status: 200,
                   body: response_body,
                   headers: { accept: 'application/json' })
    end

    let(:google_plus_account_fetcher) { described_class.new(email_address) }

    context 'when the api email_address is associated to google plus account' do
      let(:email_address) { build(:email_address) }
      let(:account_id) { 'random_account_id' }
      let(:profile_picture_link) { 'pics.google.com/random_account_id' }

      let(:response_body) do
        "{\"gphoto$user\": {\"$t\": \"#{account_id}\"}, \"gphoto$thumbnail\": {\"$t\": \"#{profile_picture_link}\"}}"
      end

      it 'builds the proper google_plus_account object from the google api response' do
        google_plus_account = google_plus_account_fetcher.fetch_google_plus_account

        expect(google_plus_account.account_id).to eq(account_id)
        expect(google_plus_account.profile_picture_link).to eq(profile_picture_link)
      end
    end

    context 'when the api email_address is associated to google plus account' do
      let(:email_address) { build(:email_address, email: 'random@gmail.com') }

      let(:response_body) { "Unable to find user with email #{email_address}" }

      it 'builds the proper google_plus_account object from the google api response' do
        expect(google_plus_account_fetcher.fetch_google_plus_account).to be_nil
      end
    end
  end
end
