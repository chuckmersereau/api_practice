require 'spec_helper'

describe Person::GoogleAccount do
  describe 'create from auth' do
    it 'should create an account linked to a person' do
      auth_hash = Hashie::Mash.new(uid: '1',
                                   info: { email: 'foo@example.com' },
                                   credentials: { token: 'a', refresh_token: 'b', expires: true, expires_at: Time.now.to_i + 100 })
      person = FactoryGirl.create(:person)
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
      person = FactoryGirl.create(:person)
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

  context '#refresh_token!' do
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

    it 'returns false and alerts refresh needed on invalid grant' do
      stub_refresh_request('{"error":"invalid_grant"}', 403)
      expect(subject).to receive(:needs_refresh)
      expect(subject.refresh_token!).to be_falsey
    end

    it 'fails if it receives another error type' do
      stub_refresh_request('{"error":"internal err"}', 500)
      expect { subject.refresh_token! }.to raise_error(/internal err/)
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
