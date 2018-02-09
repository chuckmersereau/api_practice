require 'rails_helper'

RSpec.describe DonationImports::Siebel::ProfileImporter do
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:organization_account) { user.organization_accounts.first }
  let(:organization) { organization_account.organization }

  let(:key_account) { user.key_accounts.first }

  let(:designation_profile) { organization_account.designation_profiles.first }
  let(:designation_account) do
    create(:designation_account, designation_profiles: [designation_profile],
                                 designation_number: 'designation_number',
                                 organization: organization)
  end

  let(:mock_siebel_import) { double(:mock_siebel_import) }
  let(:mock_profile_linker) { double(:mock_profile_linker) }

  before do
    organization_account.update(remote_id: nil)
    key_account.update(relay_remote_id: 'random_guid')

    allow(mock_siebel_import).to receive(:organization).and_return(organization)
    allow(mock_siebel_import).to receive(:organization_account).and_return(organization_account)
  end

  subject { described_class.new(mock_siebel_import) }

  ProfileStructure = Struct.new(:id, :name, :designations)
  DesignationStructure = Struct.new(:number, :description, :staff_account_id, :chartfield)
  BalanceStructure = Struct.new(:primary)

  let(:siebel_profiles) do
    [
      ProfileStructure.new(
        designation_profile.code,
        designation_profile.name,
        [DesignationStructure.new('second_designation_number', 'Joshua and Amanda Starcher (0559826)')]
      ),
      ProfileStructure.new(
        'profile_id_one',
        'Staff Account (0559826)',
        [DesignationStructure.new('designation_number', 'Joshua and Amanda Starcher (0559826)', 'employee_id')]
      )
    ]
  end

  context '#import_profiles' do
    it 'imports or updates designation_profiles from Siebel' do
      expect(SiebelDonations::Profile).to receive(:find)
        .with(ssoGuid: key_account.relay_remote_id)
        .and_return(siebel_profiles)

      expect(SiebelDonations::Balance).to receive(:find)
        .with(employee_ids: 'employee_id')
        .and_return([BalanceStructure.new(2000.00)])

      expect(AccountList::FromProfileLinker).to receive(:new)
        .with(instance_of(DesignationProfile), organization_account)
        .and_return(mock_profile_linker)

      expect(mock_profile_linker).to receive(:link_account_list!)

      expect do
        expect(subject.import_profiles).to be_truthy
      end.to change { organization.designation_profiles.count }.by(1)
        .and change { organization.designation_accounts.count }.by(1)
        .and change { designation_account.reload.staff_account_id }
        .and change { designation_account.reload.balance_updated_at }
        .and change { designation_profile.reload.balance_updated_at }

      expect(designation_account.balance).to eq(2000.00)
      expect(DesignationProfile.order(:created_at).last.balance).to eq(2000.00)
    end
  end
end
