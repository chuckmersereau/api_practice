require 'rails_helper'

describe TaskNotificationMailer do
  describe 'notify' do
    let(:account_list) { create(:account_list, users: [build(:user, email: build(:email_address))]) }
    let(:task) { create(:task, account_list: account_list) }
    let(:contact) { create(:contact) }
    it 'renders the email correctly' do
      task.contacts << contact
      mail = TaskNotificationMailer.notify(task)
      expect(mail.to)
      expect(mail.body.raw_source).to include("https://mpdx.org/contacts/#{contact.uuid}/tasks")
    end
  end
end
