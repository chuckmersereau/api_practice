require 'rails_helper'

describe NotificationMailer do
  let!(:user) { create(:user) }
  let!(:email_address) { create(:email_address, person: user) }

  let(:account_list) { create(:account_list, designation_accounts: [des_account]) }
  let(:des_account) { build(:designation_account, name: 'Very Specific Designation Name') }
  let(:type_special_gift) { NotificationType::SpecialGift.first_or_create }
  let(:notifications_by_type) do
    {
      type_special_gift => [
        build(:notification, notification_type: type_special_gift,
                             donation: build(:donation, designation_account: des_account),
                             contact: create(:contact, account_list: account_list))
      ]
    }
  end

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

    context 'with multiple designations' do
      let(:account_list) { create(:account_list, designation_accounts: [build(:designation_account), des_account]) }

      it 'includes designation name in email' do
        mail = NotificationMailer.notify(user.reload, notifications_by_type)

        expect(mail.body.raw_source).to include(des_account.name)
      end

      it 'includes designation number in email if no name' do
        des_account.update(name: '', designation_number: '12345678')

        mail = NotificationMailer.notify(user.reload, notifications_by_type)

        expect(mail.body.raw_source).to include(des_account.designation_number)
      end
    end

    context 'with a single designation' do
      it 'does not include designation name in email' do
        mail = NotificationMailer.notify(user.reload, notifications_by_type)

        expect(mail.body.raw_source).to_not include(des_account.name)
      end
    end
  end
end
