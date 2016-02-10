require 'spec_helper'

describe Person::OrganizationAccount do
  let(:org_account) do
    create(:organization_account,
           organization: create(:fake_org, name: 'MyString'))
  end
  let(:api) { FakeApi.new }

  before do
    allow(org_account.organization).to receive(:api).and_return(api)
    allow(api).to receive(:profiles_with_designation_numbers)
      .and_return([{ name: 'Profile 1', code: '', designation_numbers: ['1234'] }])
  end

  context '#import_all_data' do
    it 'updates the last_download column if no donations are downloaded' do
      org_account.downloading = false
      org_account.last_download = nil
      org_account.send(:import_all_data)
      expect(org_account.reload.last_download).to be_nil
    end

    context 'when password error' do
      before do
        allow(api).to receive(:import_all).and_raise(OrgAccountInvalidCredentialsError)
        org_account.person.email = 'foo@example.com'

        org_account.downloading = false
        org_account.locked_at = nil
        expect(org_account.new_record?).to be false
      end
      it 'rescues invalid password error' do
        expect do
          org_account.import_all_data
        end.to_not raise_error
      end
      it 'sends email' do
        org_account.import_all_data
        expect(ActionMailer::Base.deliveries.last.to.first).to eq(org_account.person.email.email)
      end
      it 'marks as not valid' do
        org_account.import_all_data
        expect(org_account.valid_credentials).to be false
      end
    end
  end

  context '#setup_up_account_list' do
    let(:account_list) { create(:account_list) }

    it "doesn't create a new list if an existing list contains only the designation number for a profile" do
      account_list.designation_accounts << create(:designation_account, designation_number: '1234')

      expect do
        org_account.send(:set_up_account_list)
      end.to_not change(AccountList, :count)
    end

    it "doesn't create a new designation profile if linking to an account list that already has one" do
      account_list.designation_accounts << create(:designation_account, designation_number: '1234')
      create(:designation_profile, name: 'Profile 1', account_list: account_list)

      expect do
        org_account.send(:set_up_account_list)
      end.to_not change(DesignationProfile, :count)
    end
  end

  context '#to_s' do
    it 'makes a pretty string' do
      expect(org_account.to_s).to eq('MyString: foo')
    end
  end
end
