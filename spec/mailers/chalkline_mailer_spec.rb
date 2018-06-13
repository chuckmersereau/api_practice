require 'rails_helper'

describe ChalklineMailer do
  describe 'email' do
    let(:account_list) { create(:account_list) }
    let(:contact) { create(:contact, account_list: account_list) }

    it 'pulls in the newsletter list, and users name and emails from account list' do
      expect(account_list).to receive(:users_combined_name).and_return('John and Jane Doe')
      expect(account_list).to receive(:user_emails_with_names).and_return(['john@d.com', 'jane@d.com'])
      expect(CsvExport).to receive(:mailing_addresses).with(account_list.contacts).and_return("a,b\n1,2\n")

      time = Time.new(2013, 3, 15, 18, 35, 20).getlocal
      expect(Time).to receive(:now).at_least(:once).and_return(time)
      expect(time).to receive(:in_time_zone).with(ChalklineMailer::TIME_ZONE).and_return(time)

      email = ChalklineMailer.mailing_list(account_list)
      expect(email.subject).to eq('MPDX List: John and Jane Doe')
      expect(email.cc).to eq(['john@d.com', 'jane@d.com'])
      expect(email.reply_to).to eq(['john@d.com', 'jane@d.com'])

      expect(email.attachments.size).to eq(1)
      expect(email.attachments.first.filename).to eq('john_and_jane_doe_20130315_635pm.csv')
      expect(email.attachments.first.mime_type).to eq('text/csv')
      expect(email.attachments.first.body).to eq("a,b\n1,2\n")
    end
  end
end
