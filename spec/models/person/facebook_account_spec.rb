require 'spec_helper'

describe Person::FacebookAccount do
  describe 'when authenticating' do
    before do
      @auth_hash = Hashie::Mash.new(uid: '5', credentials: { token: 'a', expires_at: 5 }, info: { first_name: 'John', last_name: 'Doe' })
    end
    describe 'create from auth' do
      it 'creates an account linked to a person' do
        person = create(:person)
        expect do
          @account = Person::FacebookAccount.find_or_create_from_auth(@auth_hash, person)
        end.to change(Person::FacebookAccount, :count).by(1)
        expect(person.facebook_accounts).to include(@account)
      end
    end

    describe 'create user from auth' do
      it 'creates a user with a first and last name' do
        expect do
          user = Person::FacebookAccount.create_user_from_auth(@auth_hash)
          expect(user.first_name).to eq(@auth_hash.info.first_name)
          expect(user.last_name).to eq(@auth_hash.info.last_name)
        end.to change(User, :count).by(1)
      end
    end

    it 'uses uid to find an authenticated user' do
      user = create(:user)
      Person::FacebookAccount.find_or_create_from_auth(@auth_hash, user)
      expect(Person::FacebookAccount.find_authenticated_user(@auth_hash)).to eq(user)
    end
  end

  it 'returns name for to_s' do
    account = Person::FacebookAccount.new(first_name: 'John', last_name: 'Doe')
    expect(account.to_s).to eq('John Doe')
  end

  it 'generates a facebook url if there is a remote_id' do
    account = Person::FacebookAccount.new(remote_id: 1)
    expect(account.url).to eq('https://www.facebook.com/profile.php?id=1')
  end

  describe 'setting & getting facebook url which includes id/username' do
    let(:account) { Person::FacebookAccount.new }

    it 'defaults to url to nil' do
      expect(account.url).to be_nil
    end

    it 'sets and gets the url based on username' do
      account.url = 'http://www.facebook.com/john.doe'
      expect(account.username).to eq('john.doe')
      expect(account.url).to eq('https://www.facebook.com/john.doe')
    end

    it 'sets and gets the url based on id' do
      account.url = 'facebook.com/profile.php?id=1'
      expect(account.remote_id).to eq(1)
      expect(account.url).to eq('https://www.facebook.com/profile.php?id=1')
    end
  end

  context '#token_missing_or_expired?' do
    it 'returns true if the token is expired' do
      stub_request(:post, 'https://graph.facebook.com/oauth/access_token')
        .to_return(status: 401, body: '')

      account = Person::FacebookAccount.new(token: 'asdf', token_expires_at: 10.days.ago)

      expect(account.token_missing_or_expired?).to be true
    end

    it 'tries to refresh once if the token is expired' do
      account = Person::FacebookAccount.new(token: 'asdf', token_expires_at: 10.days.ago)
      expect(account).to receive(:refresh_token)

      expect(account.token_missing_or_expired?).to be true
    end

    it 'returns true if the token is missing' do
      account = Person::FacebookAccount.new(token: '', token_expires_at: 10.days.from_now)

      expect(account.token_missing_or_expired?).to be true
    end

    it 'returns false if the token is not expired' do
      account = Person::FacebookAccount.new(token: 'asdf', token_expires_at: 10.days.from_now)

      expect(account.token_missing_or_expired?).to be false
    end
  end
end
