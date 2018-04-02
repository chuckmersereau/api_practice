require 'rails_helper'

RSpec.describe DonationImports::Siebel::DonorImporter do
  let!(:user) { create(:user_with_account) }

  let(:organization_account) { user.organization_accounts.first }
  let(:organization) { organization_account.organization }

  let(:designation_profile) { organization_account.designation_profiles.first }
  let!(:designation_account) do
    create(:designation_account, designation_profiles: [designation_profile],
                                 designation_number: 'the_designation_number')
  end

  let(:mock_siebel_import) { double(:mock_siebel_import) }
  let(:mock_profile) { double(:mock_profile) }

  let!(:first_donor_account) { create(:donor_account, organization: organization, account_number: 'donor_id_one') }
  let!(:second_donor_account) { create(:donor_account, organization: organization, account_number: 'donor_id_two') }

  before do
    allow(mock_siebel_import).to receive(:organization).and_return(organization)
    allow(mock_siebel_import).to receive(:organization_account).and_return(organization_account)
    allow(mock_siebel_import).to receive(:parse_date).and_return(1.week.ago)
  end

  subject { described_class.new(mock_siebel_import) }

  DonorStruct = Struct.new(:id, :account_name, :type, :addresses, :contacts)
  AddressStruct = Struct.new(:id, :address1, :primary, :address2, :address3, :address4,
                             :city, :state, :zip, :seasonal, :type, :updated_at)
  PersonStruct = Struct.new(:id, :name)

  let(:siebel_person) { PersonStruct.new('person_id_one', 'Oliver') }

  let(:siebel_donors) do
    [
      DonorStruct.new(
        'id_one',
        'Oliver',
        'Partner Financial',
        [AddressStruct.new('address_id_one', '1 angie street', true)],
        [siebel_person]
      ),
      DonorStruct.new(
        'id_one',
        "Oliver's sister",
        'Partner Financial',
        [AddressStruct.new('address_id_one', '2 angie street')],
        []
      )
    ]
  end

  context '#import_donors' do
    it 'imports donors' do
      expect(SiebelDonations::Donor).to receive(:find)
        .with(having_given_to_designations: 'the_designation_number',
              contact_filter: :all,
              account_address_filter: :primary,
              contact_email_filter: :all,
              contact_phone_filter: :all)
        .and_return(siebel_donors)

      expect_any_instance_of(described_class::PersonImporter).to receive(:add_or_update_person_on_contact)
        .with(siebel_person: siebel_person,
              donor_account: instance_of(DonorAccount),
              contact: instance_of(Contact),
              date_from: nil)

      expect do
        expect(subject.import_donors).to be_truthy
      end.to change { DonorAccount.count }.by(1)
        .and change { Contact.count }.by(1)
        .and change { Address.count }.by(2)
    end
  end
end
