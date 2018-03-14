require 'rails_helper'

RSpec.describe MailChimp::ExportContactsWorker do
  let(:mail_chimp_account) { create(:mail_chimp_account, primary_list_id: 'list_one') }

  it 'starts the export if the list used is not the primary list' do
    expect_any_instance_of(MailChimp::Exporter).to receive(:export_contacts).with([1], true)

    MailChimp::ExportContactsWorker.new.perform(mail_chimp_account.id, 'list_two', [1], true)
  end
end
