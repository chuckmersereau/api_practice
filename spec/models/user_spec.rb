require 'spec_helper'

describe User do
  subject { build(:user) }
  let(:account_list) { create(:account_list) }

  describe 'user role' do
    describe 'from omniauth' do
      before(:each) do
        user_attributes = [{ firstName: 'John', lastName: 'Doe', username: 'JOHN.DOE@EXAMPLE.COM',
                             email: 'johnnydoe@example.com', designation: '0000000', emplid: '000000000',
                             ssoGuid: 'F167605D-94A4-7121-2A58-8D0F2CA6E024' }]
        @auth_hash = Hashie::Mash.new(uid: 'JOHN.DOE@EXAMPLE.COM', extra: { attributes: user_attributes })
      end

      it 'should create a new user from omniauth' do
        FactoryGirl.create(:ccc)
        expect do
          User.from_omniauth(Person::RelayAccount, @auth_hash)
        end.to change(User, :count).by(1)
      end
    end
  end

  describe 'fundraiser role' do
    before(:each) do
      @org = FactoryGirl.create(:organization)
      @user = FactoryGirl.create(:user)
      FactoryGirl.create(:designation_profile, organization: @org, user: @user)
      @account = FactoryGirl.create(:designation_account, organization: @org)
      @account_list = FactoryGirl.create(:account_list)
      FactoryGirl.create(:account_list_entry, account_list: @account_list, designation_account: @account)
      FactoryGirl.create(:account_list_user, account_list: @account_list, user: @user)
    end

    it 'should return a list of account numbers from a given org' do
      expect(@user.designation_numbers(@org.id)).to include(@account.designation_number)
    end
  end

  context '#can_manage_sharing?' do
    it 'can manage sharing if it has a designation profile for account list' do
      expect(subject.can_manage_sharing?(account_list)).to be false
    end

    it 'cannot manage sharing if it does not have a designation profile for it' do
      subject.save
      create(:designation_profile, account_list: account_list, user: subject)
      expect(subject.can_manage_sharing?(account_list)).to be true
    end
  end

  context '#remove_access' do
    it 'removes user from account list users' do
      subject.save
      account_list.users << subject
      subject.remove_access(account_list)
      expect(account_list.reload.users).to_not include subject
    end
  end

  context '.get_user_from_cas_oauth' do
    it 'looks up the user by guid case-insensitive' do
      user = create(:user)
      relay_account = create(:relay_account, relay_remote_id: 'AAAA-0000')
      user.relay_accounts << relay_account
      token = 'token123'
      allow(RestClient).to receive(:get).with('http://oauth.ccci.us/users/token123')
        .and_return('{"guid":"aaaa-0000"}')

      result_user = User.get_user_from_cas_oauth(token)

      expect(result_user.access_token).to eq 'token123'
      expect(result_user.id).to eq user.id
    end
  end
end
