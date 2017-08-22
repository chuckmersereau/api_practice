require 'rails_helper'

describe User do
  subject { build(:user) }
  let(:account_list) { create(:account_list) }
  it { is_expected.to have_many(:options).dependent(:destroy) }

  context '#validations' do
    context '#default_account_list_is_valid' do
      let(:user) { build(:user, default_account_list: account_list.id) }

      it "doesn't allow you to save a default_account_list unless the account_list is associated to the user" do
        expect(user.valid?).to be_falsey
        user.account_lists << account_list
        expect(user.valid?).to be_truthy
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

  context '.find_by_guid' do
    it 'finds a person with a relay account' do
      user = create(:user)
      user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')
      found_user = User.find_by_guid('B163530-7372-551R-KO83-1FR05534129F')
      expect(found_user.id).to eq user.id
      expect(found_user).to be_a User
    end

    it 'finds a person with a key account' do
      user = create(:user)
      user.key_accounts << create(:key_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F') # Key and relay account models both use the same db table
      found_user = User.find_by_guid('B163530-7372-551R-KO83-1FR05534129F')
      expect(found_user.id).to eq user.id
      expect(found_user).to be_a User
    end

    it 'returns nil if user is not found' do
      expect(User.find_by_guid('B163530-7372-551R-KO83-1FR05534129F')).to be_nil
    end
  end

  context 'contacts_filter=' do
    it 'merges instead of mass assigns' do
      user = create(:user, contacts_filter: {
                      '1' => {
                        test: 'asdf'
                      }
                    })

      user.update(contacts_filter: {
                    '2' => {
                      status: ['Partner - Financial']
                    }
                  })

      user.reload
      expect(user.contacts_filter['1']).to_not be_nil
      expect(user.contacts_filter['2']).to_not be_nil
    end
  end

  describe '#assign_time_zone' do
    let(:user) { build(:user) }

    context "when the value isn't an ActiveSupport::Timezone object" do
      it 'raises an Argument Error' do
        expect { user.assign_time_zone('Non Time Zone Object') }
          .to raise_error(ArgumentError)
      end
    end

    context 'when the value is an ActiveSupport::Timezone object' do
      let(:different_time_zone) do
        ActiveSupport::TimeZone.all.detect { |zone| zone != Time.zone }
      end

      it "changes the user's timezone" do
        expect(user.time_zone).to eq Time.zone.name
        user.assign_time_zone(different_time_zone)

        expect(user.time_zone).to     eq different_time_zone.name
        expect(user.time_zone).not_to eq Time.zone.name
      end
    end
  end

  describe '#find_by_email' do
    let!(:user) { create(:user) }
    let!(:relay_account) { create(:relay_account, email: 'test@email.com', person: user) }

    it 'returns the user with a relay account associated to a provided email' do
      expect(User.find_by_email('test@email.com')).to eq(user)
    end
  end

  describe '#setup' do
    describe 'no account lists' do
      let(:user) { create(:user) }
      it 'return no account_lists' do
        expect(user.setup).to eq('no account_lists')
      end
    end

    describe 'no default_account_list' do
      let(:account_list) { create(:account_list) }
      let(:user) { create(:user, account_lists: [account_list]) }
      it 'return no default_account_list' do
        expect(user.setup).to eq('no default_account_list')
      end
    end

    describe 'no organization_account on default_account_list' do
      let(:account_list) { create(:account_list) }
      let(:user) do
        create(:user,
               account_lists: [account_list],
               preferences: { default_account_list: account_list.id })
      end
      it 'return true' do
        expect(user.setup).to eq('no organization_account on default_account_list')
      end
    end

    describe 'organization_account on default_account_list' do
      let!(:organization_account) { create(:organization_account, user: user) }
      let(:account_list) { create(:account_list) }
      let(:user) do
        create(:user,
               account_lists: [account_list],
               preferences: { default_account_list: account_list.id })
      end
      it 'return nil' do
        expect(user.setup).to be_nil
      end
    end
  end

  describe '#default_account_list_record' do
    describe 'default_account_list set' do
      let(:account_list) { create(:account_list) }
      let(:user) do
        create(:user,
               account_lists: [account_list],
               preferences: { default_account_list: account_list.id })
      end
      it 'returns account_list' do
        expect(user.default_account_list_record).to eq account_list
      end
    end
    describe 'default_account_list not set' do
      let(:account_list) { create(:account_list) }
      let(:user) { create(:user, account_lists: [account_list]) }
      it 'returns nil' do
        expect(user.default_account_list_record).to be_nil
      end
    end
  end
end
