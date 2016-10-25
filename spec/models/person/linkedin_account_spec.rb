require 'spec_helper'

describe Person::LinkedinAccount do
  describe 'create from auth' do
    it 'should create an account linked to a person' do
      auth_hash = Hashie::Mash.new(uid: '5',
                                   credentials: { token: 'a', secret: 'b' },
                                   extra: { access_token: { params: { oauth_expires_in: 2, oauth_authorization_expires_in: 5 } } },
                                   info: { first_name: 'John', last_name: 'Doe' })
      person = FactoryGirl.create(:person)
      expect do
        @account = Person::LinkedinAccount.find_or_create_from_auth(auth_hash, person)
      end.to change(Person::LinkedinAccount, :count).from(0).to(1)
      expect(person.linkedin_accounts).to include(@account)
    end
  end
  it 'should return name for to_s' do
    account = Person::LinkedinAccount.new(first_name: 'John', last_name: 'Doe')
    expect(account.to_s).to eq('John Doe')
  end

  it 'adds http:// to url if necessary' do
    account = build(:linkedin_account)
    expect(Person::LinkedinAccount).to receive(:valid_token).and_return([account])
    stub_request(:get, 'https://api.linkedin.com/v1/people/url=http:%2F%2Fwww.linkedin.com%2Fpub%2Fchris-cardiff%2F6%2Fa2%2F62a:(id,first-name,last-name,public-profile-url)')
      .to_return(status: 200, body: '{"first_name":"Chris","id":"F_ZUsSGtL7","last_name":"Cardiff","public_profile_url":"http://www.linkedin.com/pub/chris-cardiff/6/a2/62a"}', headers: {})

    url = 'www.linkedin.com/pub/chris-cardiff/6/a2/62a'
    l = Person::LinkedinAccount.new(url: url)
    expect(l.url).to eq('http://' + url)
  end

  context '#url=' do
    it "doesn't contact linkedin.com if the url han't changed" do
      account = create(:linkedin_account)

      expect(Person::LinkedinAccount).to_not receive(:valid_token)
      account.update_attributes(url: account.public_url)
    end

    it 'raises LinkedIn::Errors::UnauthorizedError if there are no accounts with a valid token' do
      account = create(:linkedin_account, valid_token: false)

      expect do
        account.update_attributes(url: 'http://bar.com')
      end.to raise_error(LinkedIn::Errors::UnauthorizedError)
    end

    it 'looks for a second valid account if the first one it finds raises an error' do
      account1 = create(:linkedin_account)
      account2 = create(:linkedin_account)
      expect(Person::LinkedinAccount).to receive(:valid_token).once.and_return([account1])
      expect(Person::LinkedinAccount).to receive(:valid_token).once.and_return([account2])

      expect(LINKEDIN).to receive(:authorize_from_access).once.and_raise(LinkedIn::Errors::UnauthorizedError, 'asdf')
      expect(LINKEDIN).to receive(:authorize_from_access).once.and_return(true)
      stub_request(:get, 'https://api.linkedin.com/v1/people/url=http:%2F%2Fwww.linkedin.com%2Fpub%2Fchris-cardiff%2F6%2Fa2%2F62a:(id,first-name,last-name,public-profile-url)')
        .to_return(status: 200, body: '{"first_name":"Chris","id":"F_ZUsSGtL7","last_name":"Cardiff","public_profile_url":"http://www.linkedin.com/pub/chris-cardiff/6/a2/62a"}', headers: {})

      expect do
        account2.update_attributes(url: 'www.linkedin.com/pub/chris-cardiff/6/a2/62a')
      end.to change(account1, :valid_token).from(true).to(false)
    end
  end
end
