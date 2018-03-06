require 'rails_helper'

describe TaskNotificationMailer do
  describe 'notify' do
    let(:user) { create(:user, email: create(:email_address)) }
    let(:account_list) { create(:account_list, users: [user]) }
    let(:task) { create(:task, account_list: account_list) }
    let(:contact) { create(:contact) }
    it 'renders the email correctly' do
      task.contacts << contact
      mail = TaskNotificationMailer.notify(task.id, user.id)
      expect(mail.to)
      expect(mail.body.raw_source).to include("https://mpdx.org/contacts/#{contact.id}/tasks")
    end
  end
end
