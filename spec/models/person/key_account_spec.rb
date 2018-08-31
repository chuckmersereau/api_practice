require 'rails_helper'

describe Person::KeyAccount do
  let!(:organization) { Organization.find_by(code: 'CCC-USA') || create(:ccc) }
  let(:user) { create(:user) }
  let(:person) { create(:person) }
  let(:auth_hash) do
    Hashie::Mash.new(
      uid: 'john.doe@example.com',
      extra: {
        attributes: [{
          firstName: 'John', lastName: 'Doe', email: 'johnnydoe@example.com',
          ssoGuid: 'F167605D-94A4-7121-2A58-8D0F2CA6E024',
          relayGuid: 'F167605D-94A4-7121-2A58-8D0F2CA6E024',
          keyGuid: 'F167605D-94A4-7121-2A58-8D0F2CA6E024'
        }]
      }
    )
  end

  describe 'create from auth' do
    it 'should create an account linked to a person' do
      allow_any_instance_of(Person::KeyAccount).to receive(:find_or_create_org_account)
      account = nil
      expect do
        account = Person::KeyAccount.find_or_create_from_auth(auth_hash, person)
      end.to change(Person::KeyAccount, :count).by(1)
      expect(person.key_accounts.pluck(:id)).to include(account.id)
    end
  end

  describe 'create user from auth' do
    let(:user) { Person::KeyAccount.create_user_from_auth(auth_hash) }
    it 'should create a user with a first and last name' do
      expect do
        expect(user.first_name).to eq auth_hash.extra.attributes.first.firstName
        expect(user.last_name).to eq auth_hash.extra.attributes.first.lastName
      end.to change(User, :count).by(1)
    end
  end

  it 'should use guid to find an authenticated user' do
    allow_any_instance_of(Person::KeyAccount).to receive(:find_or_create_org_account)
    Person::KeyAccount.find_or_create_from_auth(auth_hash, user)
    expect(Person::KeyAccount.find_authenticated_user(auth_hash)).to eq(user)
  end

  it 'should raise_or_notify exeception raised by siebel for an authenticated user with organization_account' do
    create(:organization_account, user: user)
    expect(SiebelDonations::Profile).to receive(:find).with(ssoGuid: auth_hash.extra.attributes.first.ssoGuid) do
      raise RestClient::Exception
    end
    expect(Rollbar).to receive(:raise_or_notify)
    Person::KeyAccount.find_or_create_from_auth(auth_hash, user)
  end

  it 'should use guid to find an authenticated user created with Relay' do
    allow_any_instance_of(Person::KeyAccount).to receive(:find_or_create_org_account)
    expect do
      Person::KeyAccount.find_or_create_from_auth(auth_hash, user)
    end.to change(Person::KeyAccount, :count).by(1)
    expect(Person::KeyAccount.find_authenticated_user(auth_hash)).to eq(user)
  end

  it 'should return name for to_s' do
    account = Person::KeyAccount.new(username: 'foobar@example.com')
    expect(account.to_s).to eq('foobar@example.com')
  end

  describe 'relay_account' do
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
          @account = Person::KeyAccount.find_or_create_from_auth(@auth_hash, person)
        end.to change(Person::KeyAccount, :count).by(1)
        expect(person.key_accounts.pluck(:id)).to include(@account.id)
      end

      it 'should gracefully handle a duplicate' do
        @person = create(:user)
        @person2 = create(:user)
        allow(@org).to receive(:api).and_return(FakeApi.new)
        @account = Person::KeyAccount.find_or_create_from_auth(@auth_hash, @person)
        expect do
          @account2 = Person::KeyAccount.find_or_create_from_auth(@auth_hash, @person2)
        end.to_not change(Person::KeyAccount, :count)
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
          @account = Person::KeyAccount.find_or_create_from_auth(@auth_hash, person)
        end.to change(Person::OrganizationAccount, :count).by(1)
      end
    end

    describe 'create user from auth' do
      it 'should create a user with a first and last name' do
        expect do
          user = Person::KeyAccount.create_user_from_auth(@auth_hash)
          expect(user.first_name).to eq @auth_hash.extra.attributes.first.firstName
          expect(user.last_name).to eq @auth_hash.extra.attributes.first.lastName
        end.to change(User, :count).by(1)
      end
    end

    it 'should use guid to find an authenticated user' do
      user = create(:user)
      allow(@org).to receive(:api).and_return(FakeApi.new)
      Person::KeyAccount.find_or_create_from_auth(@auth_hash, user)
      expect(Person::KeyAccount.find_authenticated_user(@auth_hash)).to eq user
    end

    it 'should return name for to_s' do
      account = Person::KeyAccount.new(username: 'foobar@example.com')
      expect(account.to_s).to eq('foobar@example.com')
    end
  end
end
