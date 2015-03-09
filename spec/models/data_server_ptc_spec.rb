require 'spec_helper'

describe DataServerPtc do
  let(:account_list) { create(:account_list) }
  let(:profile) { create(:designation_profile, organization: @org, user: @person.to_user, account_list: account_list) }

  before(:each) do
    @org = create(:nav)
    @person = create(:person)
    @org_account = build(:organization_account, person: @person, organization: @org)
    @data_server = DataServerPtc.new(@org_account)
  end
  describe 'import account balances' do
    it 'should update a profile balance' do
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"\",\"2/10/15 10:13:38\",\"123.45\",\"Test Account\"\n")
      @data_server.should_receive(:check_credentials!)
      expect do
        @data_server.import_profile_balance(profile)
      end.to change(profile, :balance).to(123.45)
    end
    it 'should update a designation account balance' do
      stub_request(:post, /.*accounts/).to_return(body: "\"EMPLID\",\"EFFDT\",\"BALANCE\",\"ACCT_NAME\"\n\"#{@org_account.username}\",\"2/10/15 10:13:38\",\"123.45\",\"Test Account\"\n")
      @designation_account = create(:designation_account, organization: @org, designation_number: @org_account.username)
      @data_server.import_profile_balance(profile)
      @designation_account.reload.balance.should == 123.45
    end
  end
end
