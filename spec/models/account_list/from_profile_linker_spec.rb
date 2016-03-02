require 'spec_helper'

describe AccountList::FromProfileLinker do
  context '#link_account_list' do
    let(:org_account) { create(:organization_account) }
    let(:profile) do
      create(:designation_profile, user_id: org_account.person_id,
                                   organization: org_account.organization)
    end

    it 'creates a new account list if none is found' do
      da = create(:designation_account, organization: org_account.organization)
      profile.designation_accounts << da
      expect do
        AccountList::FromProfileLinker.new(profile, org_account).link_account_list!
      end.to change(AccountList, :count).by(1)
    end

    it 'does not create a new account list if one is found' do
      da = create(:designation_account, organization: org_account.organization)
      profile.designation_accounts << da
      account_list = create(:account_list)
      profile2 = create(:designation_profile, account_list: account_list)
      profile2.designation_accounts << da

      expect do
        AccountList::FromProfileLinker.new(profile, org_account).link_account_list!
      end.to_not change(AccountList, :count)
    end
  end
end
