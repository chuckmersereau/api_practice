require 'rails_helper'

describe OfflineOrg do
  let(:account_list) { create(:account_list) }
  let(:profile) { create(:designation_profile, organization: @org, user: @person.to_user, account_list: account_list) }

  before(:each) do
    @org = create(:organization, name: 'MyString', api_class: 'OfflineOrg')
    @person = create(:person)
    @org_account = build(:organization_account, person: @person, organization: @org)
  end

  context '.import_profiles' do
    let(:offline_org) { OfflineOrg.new(@org_account) }

    it 'creates designation account' do
      expect do
        offline_org.import_profiles
      end.to change(DesignationAccount, :count).from(0).to(1)
      designation_account = DesignationAccount.first
      expect(designation_account.designation_number).to eq(@org_account.id.to_s)
      expect(designation_account.active).to eq(true)
      expect(designation_account.name).to eq(@org.name)
    end
  end
end
