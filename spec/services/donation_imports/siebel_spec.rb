require 'rails_helper'

RSpec.describe DonationImports::Siebel do
  let(:organization_account) { create(:organization_account) }
  let(:organization) { organization_account.organization }

  let(:mock_profile_importer) { double(:mock_profile_importer) }
  let(:mock_donor_importer) { double(:mock_donor_importer) }
  let(:mock_donation_importer) { double(:mock_donation_importer) }

  subject { described_class.new(organization_account) }

  describe '#import_data' do
    it 'imports profiles, donors and donations' do
      expect(described_class::ProfileImporter).to receive(:new).with(subject).and_return(mock_profile_importer)
      expect(mock_profile_importer).to receive(:import_profiles)

      expect(described_class::DonorImporter).to receive(:new).with(subject).and_return(mock_donor_importer)
      expect(mock_donor_importer).to receive(:import_donors)

      expect(described_class::DonationImporter).to receive(:new).with(subject).and_return(mock_donation_importer)
      expect(mock_donation_importer).to receive(:import_donations)

      subject.import_data
    end
  end
end
