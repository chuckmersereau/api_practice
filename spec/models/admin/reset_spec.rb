require 'rails_helper'

describe Admin::Reset, '#reset!' do
  let!(:admin_user) { create(:admin_user) }
  let!(:resetted_user) { create(:user_with_full_account) }
  let!(:user_finder) { Admin::UserFinder }
  let!(:reset_logger) { Admin::ResetLog }
  let!(:resetted_user_email) { 'resetted_user@internet.com' }
  let!(:account_list) { resetted_user.account_lists.order(:created_at).first }

  before do
    Sidekiq::Testing.inline!
    resetted_user.key_accounts.first.update!(email: resetted_user_email)
  end

  describe '.reset!' do
    it 'performs a reset' do
      expect do
        expect(Admin::Reset.reset!(
                 reason: 'because', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
                 user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
        )).to eq(true)
      end.to change(AccountListUser, :count).by(-1)
        .and change(AccountList, :count).by(-1)
        .and change(Admin::ResetLog, :count).by(1)
    end

    it 'performs the reset by insantiating a new instance' do
      expect(Admin::Reset).to receive(:new).and_return(Admin::Reset.new)
      expect_any_instance_of(Admin::Reset).to receive(:reset!)
      Admin::Reset.reset!
    end
  end

  describe '#reset!' do
    it 'finds the user to reset and logs the reset' do
      subject = Admin::Reset.new(
        reason: 'because', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect(subject.reset!).to eq(true)
      end.to change(AccountListUser, :count).by(-1)
        .and change(AccountList, :count).by(-1)
        .and change(Admin::ResetLog, :count).by(1)
    end

    it 'returns false and adds an error if no users found' do
      subject = Admin::Reset.new(
        reason: 'because', admin_resetting: admin_user, resetted_user_email: 'random@g.com',
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect(subject.reset!).to eq(false)
      end.to_not change(AccountList, :count)

      expect(Admin::ResetLog.count).to eq(0)
      expect(subject.errors[:resetted_user]).to be_present
    end

    it 'returns false and adds error if no reason given' do
      subject = Admin::Reset.new(
        reason: '', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect(subject.reset!).to eq(false)
      end.to_not change(AccountList, :count)

      expect(Admin::ResetLog.count).to eq(0)
      expect(subject.errors[:reason]).to be_present
    end

    it 'returns false and adds error if account list cannot be found' do
      AccountList.delete_all

      subject = Admin::Reset.new(
        reason: 'test', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect(subject.reset!).to eq(false)
      end.to_not change(AccountList, :count)

      expect(Admin::ResetLog.count).to eq(0)
      expect(subject.errors[:account_list]).to be_present
    end

    it 'returns false and adds error if multiple account lists are found' do
      resetted_user.account_lists << create(:account_list, name: account_list.name)

      subject = Admin::Reset.new(
        reason: 'test', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect(subject.reset!).to eq(false)
      end.to_not change(AccountList, :count)

      expect(Admin::ResetLog.count).to eq(0)
      expect(subject.errors[:account_list]).to be_present
    end

    it 'raises unauthorized error if admin_resetting is not an admin' do
      subject = Admin::Reset.new(
        reason: 'because', admin_resetting: resetted_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect do
        expect { subject.reset! }.to raise_error(Pundit::NotAuthorizedError)
      end.to_not change(AccountList, :count)
      expect(Admin::ResetLog.count).to eq(0)
    end

    it 'sends an email notifying the reset user to logout and login again' do
      subject = Admin::Reset.new(
        reason: 'because', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )

      expect_delayed_email(AccountListResetMailer, :logout)
      subject.reset!
    end
  end

  describe '#account_list' do
    it 'returns the located account list' do
      subject = Admin::Reset.new(
        reason: 'because', admin_resetting: admin_user, resetted_user_email: resetted_user_email,
        user_finder: user_finder, reset_logger: reset_logger, account_list_name: account_list.name
      )
      expect(subject.account_list).to eq(account_list)
    end
  end
end
