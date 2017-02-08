require 'rails_helper'

describe Admin::Reset, '#reset!' do
  let(:admin_user) { create(:admin_user) }
  let(:resetted_user) { create(:user_with_account) }
  let(:user_finder) { spy('user_finder', find_users: [resetted_user]) }
  let(:reset_logger) { double('logger', create!: nil) }

  it 'finds the user to reset and logs the reset' do
    subject = Admin::Reset.new(
      reason: 'because', admin_resetting: admin_user, resetted_user: resetted_user,
      user_finder: user_finder, reset_logger: reset_logger
    )

    expect do
      expect(subject.reset!).to eq(true)
    end.to change(AccountListUser, :count).by(-1)
  end

  it 'returns false and adds an error if no users found' do
    subject = Admin::Reset.new(
      reason: 'because', admin_resetting: admin_user, resetted_user_email: 'random@g.com',
      user_finder: user_finder, reset_logger: reset_logger
    )

    result = subject.reset!

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end

  it 'returns false and adds error if no reason given' do
    subject = Admin::Reset.new(
      reason: nil, admin_resetting: admin_user, resetted_user: resetted_user,
      user_finder: user_finder, reset_logger: reset_logger
    )

    result = subject.reset!

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end
end
