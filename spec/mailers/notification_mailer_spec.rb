require 'spec_helper'

describe NotificationMailer do
  describe 'notify' do
    it 'renders the email correctly' do
      notifications_by_type = {}
      email = build(:email_address)
      account_list = double(users: [double(email: email)])

      email = NotificationMailer.notify(account_list, notifications_by_type)

      expect(email.to)
    end
  end
end
