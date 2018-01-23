require 'rails_helper'

describe TntImport::DonorAccountsImport do
  subject { described_class.new(xml, orgs_by_tnt_id) }

  let(:user) { create(:user) }
  let(:import) do
    create(:tnt_import_short_donor_code, override: true, user: user,
                                         account_list: account_list)
  end
  let(:tnt_import) { TntImport.new(import) }
  let(:xml) { tnt_import.xml }
  let(:account_list) { create(:account_list) }
  let(:designation_profile) { create(:designation_profile, account_list: account_list) }
  let(:organization) { designation_profile.organization }
  let(:orgs_by_tnt_id) { TntImport::OrgsFinder.orgs_by_tnt_id(xml, organization) }
  let(:first_donor_row) { xml.tables['Donor'].first }

  let!(:donor_account) do
    create(:donor_account, organization: organization, name: donor_account_name,
                           account_number: first_donor_row['OrgDonorCode'])
  end

  describe '#add_or_update_donor' do
    context 'donor_account has a name' do
      let(:donor_account_name) { 'A preset name' }

      it 'does not change it' do
        expect { subject.import }.not_to change { donor_account.name }
      end
    end

    context 'donor_account has no name' do
      let(:donor_account_name) { nil }

      it 'is updated from the import' do
        expect { subject.import }.to change { donor_account.reload.name }
      end
    end
  end
end
