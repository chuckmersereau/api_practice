require 'rails_helper'

describe NotificationMailer do
  let!(:user) { create(:user) }
  let!(:email_address) { create(:email_address, person: user) }
  let(:notifications_by_type) { {} }
  describe 'notify' do
    it 'renders the email correctly' do
      email = NotificationMailer.notify(user.reload, notifications_by_type)
      expect(email.to).to eq [email_address.email]
    end
  end
end
