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
end
