require 'spec_helper'

describe MailChimpSync do
  let(:account_list) { create(:account_list) }
  let(:mc_account) do
    create(:mail_chimp_account, account_list: account_list, primary_list_id: 'list1')
  end
  subject { MailChimpSync.new(mc_account) }

  context '#sync_deletes' do
    it 'unsubscribes emails to remove' do
      expect(subject).to receive(:emails_to_remove) { ['test@example.com'] }
      expect(mc_account).to receive(:unsubscribe_list_batch)
        .with('list1', ['test@example.com'])
      subject.sync_deletes
    end
  end
end
