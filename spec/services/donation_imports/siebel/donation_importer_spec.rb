require 'rails_helper'

RSpec.describe DonationImports::Siebel::DonationImporter do
  let!(:user) { create(:user_with_account) }

  let(:organization_account) { user.organization_accounts.first }
  let(:organization) { organization_account.organization }

  let!(:donor_account) { create(:donor_account, account_number: 'donor_id_one', organization: organization) }

  let(:designation_profile) { organization_account.designation_profiles.first }
  let!(:designation_account) { create(:designation_account, designation_profiles: [designation_profile], designation_number: 'the_designation_number') }

  let(:mock_siebel_import) { double(:mock_siebel_import) }
  let(:donor_account) { create(:donor_account, organization: organization, account_number: 'donor_id_one') }

  let!(:first_donation) { create(:donation, remote_id: 'id_one', donor_account: donor_account, designation_account: designation_account, amount: 400.00, donation_date: 1.week.ago) }
  let!(:second_donation) { create(:donation, remote_id: 'id_five', donor_account: donor_account, designation_account: designation_account, amount: 500.00, donation_date: 1.week.ago) }
  let!(:third_donation) { create(:donation, remote_id: 'id_seven', donor_account: donor_account, designation_account: designation_account, amount: 500.00, donation_date: 3.weeks.ago) }
  let!(:fourth_donation) { create(:donation, remote_id: 'random_id_one', donor_account: donor_account, designation_account: designation_account, donation_date: 1.week.ago) }
  let!(:fifth_donation) { create(:donation, remote_id: 'random_id_two', donor_account: donor_account, designation_account: designation_account, donation_date: 1.week.ago) }
  let!(:sixth_donation) { create(:donation, remote_id: 'random_id_three', donor_account: donor_account, designation_account: designation_account, donation_date: 1.week.ago) }

  let(:mock_profile) { double(:mock_profile) }

  before do
    allow(mock_siebel_import).to receive(:organization).and_return(organization)
    allow(mock_siebel_import).to receive(:organization_account).and_return(organization_account)
    allow(mock_siebel_import).to receive(:profiles).and_return([designation_profile])
  end

  subject { described_class.new(mock_siebel_import) }

  donation_structure_array = [
    :id,
    :donor_id,
    :amount,
    :donation_date,
    :designation,
    :campaign_code,
    :payment_method,
    :payment_type,
    :channel
  ]

  DonationStructure = Struct.new(*donation_structure_array)

  let(:siebel_donations) do
    [
      DonationStructure.new('id_one', 'donor_id_one', 200.00, 1.week.ago, 'the_designation_number'),
      DonationStructure.new('id_two', 'donor_id_one', 300.00, 1.week.ago, 'the_designation_number')
    ]
  end

  context '#import_donations' do
    it 'imports donations and deletes up to 3 donations that were removed on siebel (in the date range provided)' do
      expect(SiebelDonations::Donation).to receive(:find)
        .with(posted_date_start: 2.weeks.ago.strftime('%Y-%m-%d'),
              posted_date_end: Time.now.strftime('%Y-%m-%d'),
              designations: 'the_designation_number')
        .and_return(siebel_donations)

      expect do
        expect(subject.import_donations(start_date: 2.weeks.ago)).to be_truthy
      end.to change { Donation.count }.by(-2)

      expect(first_donation.reload.amount).to eq(200.00)
      expect(Donation.find_by(id: second_donation)).to be_nil
      expect(third_donation.reload).to be_present
    end
  end
end
