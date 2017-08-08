require 'rails_helper'

RSpec.describe MailChimp::MembersImportWorker do
  let(:mail_chimp_account) { create(:mail_chimp_account) }
  let(:email) { 'random@email.com' }

  it 'starts the sync with primary list' do
    expect_any_instance_of(MailChimp::Importer).to receive(:import_members_by_email).with([email])

    MailChimp::MembersImportWorker.new.perform(mail_chimp_account.id, [email])
  end
end
