require 'rails_helper'

describe Person::RelayAccount do
  let(:guid) { 'F167605D-94A4-7121-2A58-8D0F2CA6E024' }

  before(:each) do
    @org = Organization.find_by(code: 'CCC-USA') || create(:ccc) # Spec requires CCC-USA org to exist.
    user_attributes = [{ firstName: 'John', lastName: 'Doe', username: 'JOHN.DOE@EXAMPLE.COM',
                         email: 'johnnydoe@example.com', designation: '0000000', emplid: '000000000',
                         ssoGuid: guid, relayGuid: guid, keyGuid: guid }]
    @auth_hash = Hashie::Mash.new(uid: 'JOHN.DOE@EXAMPLE.COM', extra: { attributes: user_attributes })
    @wsapi_headers = { 'Authorization' => "Bearer #{ENV.fetch('WSAPI_KEY')}" }
    stub_request(:get, "https://wsapi.cru.org/wsapi/rest/profiles?response_timeout=600&ssoGuid=#{guid}")
      .with(headers: @wsapi_headers)
      .to_return(status: 200, body: '[]', headers: {})
  end

  describe 'find or create from auth' do
    it 'should create an account linked to a person' do
      person = create(:user)
      allow(@org).to receive(:api).and_return(FakeApi.new)
      expect do
        @account = Person::RelayAccount.find_or_create_from_auth(@auth_hash, person)
      end.to change(Person::RelayAccount, :count).by(1)
      expect(person.relay_accounts.pluck(:id)).to include(@account.id)
    end

    it 'should gracefully handle a duplicate' do
      @person = create(:user)
      @person2 = create(:user)
      allow(@org).to receive(:api).and_return(FakeApi.new)
      @account = Person::KeyAccount.find_or_create_from_auth(@auth_hash, @person)
      expect do
        @account2 = Person::KeyAccount.find_or_create_from_auth(@auth_hash, @person2)
      end.to_not change(Person::RelayAccount, :count)
      expect(@account).to eq(@account2)
    end

    it 'creates an organization account if this user has a profile at cru' do
      stub_request(:get, "https://wsapi.cru.org/wsapi/rest/profiles?response_timeout=600&ssoGuid=#{guid}")
        .with(headers: @wsapi_headers)
        .to_return(status: 200, headers: {},
                   body: '[{"name":"Staff Account(000555555)",'\
                           '"designations":[{"number":"0555555","description":"Jon and Jane Doe(000555555)",'\
                                            '"staffAccountId":"000555555"}]}]')
      person = create(:user)
      allow(@org).to receive(:api).and_return(FakeApi.new)
      expect do
        @account = Person::RelayAccount.find_or_create_from_auth(@auth_hash, person)
      end.to change(Person::OrganizationAccount, :count).by(1)
    end
  end

  describe 'create user from auth' do
    it 'should create a user with a first and last name' do
      expect do
        user = Person::RelayAccount.create_user_from_auth(@auth_hash)
        expect(user.first_name).to eq @auth_hash.extra.attributes.first.firstName
        expect(user.last_name).to eq @auth_hash.extra.attributes.first.lastName
      end.to change(User, :count).by(1)
    end
  end

  it 'should use guid to find an authenticated user' do
    user = create(:user)
    allow(@org).to receive(:api).and_return(FakeApi.new)
    Person::RelayAccount.find_or_create_from_auth(@auth_hash, user)
    expect(Person::RelayAccount.find_authenticated_user(@auth_hash)).to eq user
  end

  it 'should return name for to_s' do
    account = Person::RelayAccount.new(username: 'foobar@example.com')
    expect(account.to_s).to eq('foobar@example.com')
  end
end
