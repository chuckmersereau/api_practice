require 'spec_helper'

describe Admin::Impersonation, '#save' do
  let(:admin_user) { instance_double(User, 'admin') }
  let(:user_resetted) { instance_double(User, 'resetted') }
  let(:user_finder) { spy('user_finder', find_users: [impersonated]) }
  let(:reset_logger) { double('logger', create!: nil) }

  it 'finds the user to impersonate and logs the impersonation' do
    subject = Admin::Reset.new(
      reason: 'because', admin_user: admin_user, resetted_user: resetted_user,
      user_finder: user_finder, reset_logger: reset_logger
    )

    result = subject.reset!

    expect(result).to be true
    expect(user_resetted.reload).to eq nil
  end

  it 'returns false and adds an error if multiple users found' do
    subject = Admin::Reset.new(
      reason: 'because', admin_user: admin_user, resetted_user: User.new,
      user_finder: user_finder, reset_logger: reset_logger
    )

    result = subject.reset!

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end

  it 'returns false and adds error if no reason given' do
    subject = Admin::Reset.new(
      reason: nil, admin_user: admin_user, resetted_user: User.new,
      user_finder: user_finder, reset_logger: reset_logger
    )

    result = subject.reset!

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end
end
