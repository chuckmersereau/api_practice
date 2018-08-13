require 'rails_helper'

describe Person::GoogleAccount do
  describe 'create from auth' do
    it 'should create an account linked to a person' do
      auth_hash = Hashie::Mash.new(uid: '1',
                                   info: { email: 'foo@example.com' },
                                   credentials: { token: 'a', refresh_token: 'b', expires: true, expires_at: Time.now.to_i + 100 })
      person = FactoryBot.create(:person)
      expect do
        @account = Person::GoogleAccount.find_or_create_from_auth(auth_hash, person)
      end.to change(Person::GoogleAccount, :count).from(0).to(1)
      expect(person.google_accounts).to include(@account)
    end
  end

  describe 'update from auth' do
    it 'should update an account that already exists' do
      auth_hash = Hashie::Mash.new(uid: '1',
                                   info: { email: 'foo@example.com' },
                                   credentials: { token: 'a', refresh_token: 'b', expires: true, expires_at: Time.now.to_i + 100 })
      person = FactoryBot.create(:person)
      Person::GoogleAccount.find_or_create_from_auth(auth_hash, person)
      expect do
        @account = Person::GoogleAccount.find_or_create_from_auth(auth_hash.merge!(credentials: { refresh_token: 'c' }), person)
      end.to_not change(Person::GoogleAccount, :count)
      expect(@account.refresh_token).to eq('c')
    end
  end

  it 'should return email for to_s' do
    account = Person::GoogleAccount.new(email: 'john.doe@example.com')
    expect(account.to_s).to eq('john.doe@example.com')
  end

  describe '#contact_groups' do
    subject { create(:google_account) }

    it 'calls Person::GoogleAccount::ContactGroup' do
      expect(subject).to receive(:contacts_api_user).and_return(OpenStruct.new(groups: []))
      expect(Person::GoogleAccount::ContactGroup).to receive(:from_groups)
      subject.contact_groups
    end

    it 'returns an empty array if the refresh token is invalid' do
      expect(subject).to receive(:contacts_api_user).and_raise(Person::GoogleAccount::MissingRefreshToken)
      expect(Person::GoogleAccount::ContactGroup).to_not receive(:from_groups)
      expect(subject.contact_groups).to eq([])
    end
  end

  describe '#token_expired?' do
    context 'expires_at is in the future' do
      subject { build(:google_account, expires_at: 1.minute.from_now) }

      it 'does not attempt to refresh token' do
        expect(subject).to_not receive(:refresh_token!)
        expect(subject.token_expired?).to eq false
      end

      it 'returns false' do
        expect(subject.token_expired?).to eq false
      end
    end

    context 'expires_at is in the past' do
      subject { build(:google_account, expires_at: 1.minute.ago) }

      it 'attempts to refresh token' do
        expect(subject).to receive(:refresh_token!).and_return(true)
        expect(subject.token_expired?).to eq false
      end

      it 'returns true' do
        expect(subject).to receive(:refresh_token!).and_return(false)
        expect(subject.token_expired?).to eq true
      end
    end

    context 'expires_at is nil' do
      subject { build(:google_account, expires_at: nil) }

      it 'attempts to refresh token' do
        expect(subject).to receive(:refresh_token!).and_return(true)
        expect(subject.token_expired?).to eq false
      end

      it 'returns true' do
        expect(subject).to receive(:refresh_token!).and_return(false)
        expect(subject.token_expired?).to eq true
      end
    end
  end

  describe '#token_failure?' do
    it 'returns true if notified_failure' do
      expect(build(:google_account, notified_failure: true).token_failure?).to eq(true)
    end

    it 'returns false if not notified_failure' do
      expect(build(:google_account, notified_failure: false).token_failure?).to eq(false)
      expect(build(:google_account, notified_failure: nil).token_failure?).to eq(false)
    end
  end

  describe '#refresh_token!' do
    subject { build(:google_account) }

    before do
      ENV['GOOGLE_KEY'] = 'key'
      ENV['GOOGLE_SECRET'] = 'secret'
    end

    it 'returns false and alerts to a refresh needed if refresh token blank' do
      subject.refresh_token = nil
      expect(subject).to receive(:needs_refresh)
      expect(subject.refresh_token!).to be false
    end

    it 'updates the token and expiration on success' do
      stub_refresh_request('{"access_token":"NewToken"}')
      expect(subject.refresh_token!).to be_truthy
      expect(subject.new_record?).to be_falsey
      subject.reload
      expect(subject.token).to eq 'NewToken'
      expect(subject.expires_at).to be > 58.minutes.from_now
    end

    it 'returns false and alerts refresh needed on invalid_grant error' do
      stub_refresh_request('{"error":"invalid_grant"}', 403)
      expect(subject).to receive(:needs_refresh)
      expect(Rollbar).to_not receive(:error)
      expect(subject.refresh_token!).to be_falsey
    end

    it 'returns false and alerts refresh needed on invalid_client error' do
      stub_refresh_request('{"error":"invalid_client"}', 403)
      expect(subject).to receive(:needs_refresh)
      expect(Rollbar).to_not receive(:error)
      expect(subject.refresh_token!).to be_falsey
    end

    it 'returns false and does not alert refresh needed on an unknown error' do
      stub_refresh_request('{"error":"internal err"}', 500)
      expect(subject).to_not receive(:needs_refresh)
      expect(Rollbar).to receive(:error)
      expect(subject.refresh_token!).to be_falsey
    end

    def stub_refresh_request(body, status = 200)
      stub_request(:post, 'https://accounts.google.com/o/oauth2/token')
        .with(body: { 'client_id' => 'key',
                      'client_secret' => 'secret',
                      'grant_type' => 'refresh_token',
                      'refresh_token' => 'MyString' })
        .to_return(body: body, status: status)
    end
  end
end
