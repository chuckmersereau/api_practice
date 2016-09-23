require 'spec_helper'

describe TaskNotificationMailer do
  describe 'notify' do
    let(:account_list) { create(:account_list, users: [build(:user, email: build(:email_address))]) }
    let(:task) { create(:task, account_list: account_list) }
    it 'renders the email correctly' do
      email = TaskNotificationMailer.notify(task)
      expect(email.to)
    end
  end
end
