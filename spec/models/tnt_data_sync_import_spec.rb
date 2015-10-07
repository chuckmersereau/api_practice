require 'spec_helper'

describe TntDataSyncImport do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  before { stub_smarty_streets }

  it 'imports donors and donations, and sends notifications' do
    expect(account_list).to receive(:send_account_notifications)
    subject = build_import('tnt_data_sync_file.tntmpd')
    subject.import
    expect(account_list.contacts.count).to eq 1
    contact = account_list.contacts.first
    expect(contact.name).to eq 'Mr. and Mrs. Cliff A. Doe'
    expect(contact.people.first.first_name).to eq 'Cliff'
    expect(account_list.donations.count).to eq 1
    donation = account_list.donations.first
    expect(donation.amount).to eq 85
  end

  it 'works even if [ORGANIZATIONS] section missing and headers are lowercase' do
    subject = build_import('tnt_data_sync_no_org_lowercase_fields.tntmpd')
    expect do
      subject.import
    end.to change(Donation, :count).by(1)
  end

  it 'gives an erorr if the file has invalid data' do
    subject = build_import('tnt_data_sync_invalid.tntmpd')
    expect { subject.import }.to raise_error(Import::UnsurprisingImportError)
  end

  def build_import(file)
    TntDataSyncImport.new(
      build(:import,
            source: 'tnt_data_sync', account_list: account_list, user: user,
            file: File.new(Rails.root.join("spec/fixtures/tnt/#{file}")),
            source_account_id: user.organization_accounts.first.id)
    )
  end
end
