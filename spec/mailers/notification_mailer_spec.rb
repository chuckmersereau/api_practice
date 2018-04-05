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

    context 'with account_list_id' do
      it 'includes name of account list' do
        account_list = user.account_lists.first || create(:account_list)

        mail = NotificationMailer.notify(user.reload, notifications_by_type, account_list.id)

        expect(mail.body.raw_source).to include(account_list.name)
      end
    end

    context 'without account_list_id' do
      it 'does not includes name of account list' do
        mail = NotificationMailer.notify(user.reload, notifications_by_type)

        expect(mail.body.raw_source).to_not include("Here are today's notifications for")
      end
    end
  end
end
