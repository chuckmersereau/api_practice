require 'spec_helper'

describe Person::KeyAccount do
  before(:each) do
    @auth_hash = Hashie::Mash.new(uid: 'john.doe@example.com', extra: {
                                    attributes: [{
                                      firstName: 'John', lastName: 'Doe', email: 'johnnydoe@example.com',
                                      ssoGuid: 'F167605D-94A4-7121-2A58-8D0F2CA6E024'
                                    }]
                                  })
  end
  describe 'create from auth' do
    it 'should create an account linked to a person' do
      person = FactoryGirl.create(:person)
      expect do
        @account = Person::KeyAccount.find_or_create_from_auth(@auth_hash, person)
      end.to change(Person::KeyAccount, :count).by(1)
      expect(person.key_accounts).to include(@account)
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
    user = FactoryGirl.create(:user)
    Person::KeyAccount.find_or_create_from_auth(@auth_hash, user)
    expect(Person::KeyAccount.find_authenticated_user(@auth_hash)).to eq(user)
  end

  it 'should return name for to_s' do
    account = Person::KeyAccount.new(email: 'foobar@example.com')
    expect(account.to_s).to eq('foobar@example.com')
  end
end
