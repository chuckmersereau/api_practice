require 'rails_helper'

describe Person::OrganizationAccount do
  let(:user) { create(:user) }
  let(:organization) { create(:fake_org, name: 'MyString') }
  let(:org_account) do
    create(:organization_account,
           organization: organization,
           person: user,
           remote_id: SecureRandom.uuid)
  end
  let(:api) { FakeApi.new }

  before do
    allow(org_account.organization).to receive(:api).and_return(api)
    allow(api).to receive(:profiles_with_designation_numbers)
      .and_return([{ name: 'Profile 1', code: '', designation_numbers: ['1234'] }])
  end

  describe '.find_or_create_from_auth' do
    let(:oauth_url) { 'https://www.mytntware.com/dataserver/toontown/staffportal/oauth/authorize.aspx' }
    let!(:oauth_organization) { create(:fake_org, oauth_url: oauth_url) }

    context 'organization_account does not exist' do
      it 'creates an organization_account' do
        expect { described_class.find_or_create_from_auth('abc', oauth_url, user) }.to(
          change { described_class.count }.by(1)
        )
        organization_account = described_class.find_by(organization: oauth_organization, person: user)
        expect(organization_account.user).to eq user
        expect(organization_account.organization).to eq oauth_organization
        expect(organization_account.token).to eq 'abc'
      end

      context 'organization cannot be found' do
        it 'raise error' do
          expect { described_class.find_or_create_from_auth('abc', 'fake_url', user) }.to raise_error
        end
      end
    end

    context 'organization_account does exist' do
      let!(:organization_account) do
        create(:organization_account,
               organization: oauth_organization,
               person: user,
               token: '123')
      end

      it 'updates organization_account token' do
        expect { described_class.find_or_create_from_auth('abc', oauth_url, user) }.to_not(
          change { described_class.count }
        )
        organization_account = described_class.find_by(organization: oauth_organization, person: user)
        expect(organization_account.token).to eq 'abc'
      end
    end
  end

  describe '#import_all_data' do
    it 'updates last_download_attempt_at' do
      travel_to Time.current do
        expect { org_account.import_all_data }.to change { org_account.reload.last_download_attempt_at }.from(nil).to(Time.current)
      end
    end

    it 'does not update the last_download column if no donations downloaded' do
      org_account.downloading = false
      org_account.last_download = nil
      org_account.import_all_data
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
        expect do
          org_account.import_all_data
        end.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)
      end

      it 'marks as not valid' do
        org_account.import_all_data
        expect(org_account.valid_credentials).to be false
      end
    end

    context 'when password and username missing' do
      before do
        allow(api).to receive(:import_all).and_raise(OrgAccountMissingCredentialsError)
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
        expect do
          org_account.import_all_data
        end.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)
      end

      it 'marks as not valid' do
        org_account.import_all_data
        expect(org_account.valid_credentials).to be false
      end
    end

    context 'when previous password error' do
      it 'retries donor import but does not re-send email' do
        org_account.valid_credentials = false
        expect(api).to receive(:import_all)

        expect do
          org_account.import_all_data
        end.to_not change(Sidekiq::Extensions::DelayedMailer.jobs, :size)
      end
    end
  end

  describe '#setup_up_account_list' do
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

  describe '#to_s' do
    it 'makes a pretty string' do
      expect(org_account.to_s).to eq('MyString: foo')
    end
  end

  describe '#requires_credentials' do
    context 'organization requires username and password' do
      before do
        allow(organization).to receive(:api) { OpenStruct.new(requires_credentials?: true) }
      end

      it 'returns true' do
        expect(org_account.requires_credentials?).to eq true
      end

      context 'token is set' do
        before { org_account.token = 'abc' }

        it 'returns false' do
          expect(org_account.requires_credentials?).to eq false
        end
      end
    end

    context 'organization does not require username and password' do
      before do
        allow(organization).to receive(:api) { OpenStruct.new(requires_credentials?: false) }
      end

      it 'returns false' do
        expect(org_account.requires_credentials?).to eq false
      end
    end

    context 'organization is nil' do
      before { org_account.organization = nil }

      it 'returns false' do
        expect(org_account.requires_credentials?).to eq false
      end
    end
  end
end
