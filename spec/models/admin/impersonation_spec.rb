require 'spec_helper'

describe Admin::Impersonation, '#save' do
  it 'finds the user to impersonate and logs the impersonation' do
    impersonator = instance_double(User, 'impersonator')
    impersonated = instance_double(User, 'impersonated')
    user_finder = spy('user_finder', find_users: [impersonated])
    impersonation_logger = double('logger', create!: nil)
    subject = Admin::Impersonation.new(
      reason: 'because', impersonator: impersonator, user_finder: user_finder,
      impersonation_logger: impersonation_logger,
      impersonate_lookup: 'joe to impersonate')

    result = subject.save

    expect(user_finder).to have_received(:find_users).with('joe to impersonate')
    expect(result).to be true
    expect(subject.impersonated).to eq impersonated
    expect(impersonation_logger).to have_received(:create!).with(
      impersonator: impersonator, impersonated: impersonated, reason: 'because')
  end

  it 'returns false and adds an error if multiple users found' do
    expect_error_for_users([double(:user1), double(:user2)])
  end

  it 'returns false and adds error if no users found' do
    expect_error_for_users([])
  end

  it 'returns false and adds error if no reason given' do
    subject = Admin::Impersonation.new(user_finder: double(find_users: [double]),
                                       reason: '')

    result = subject.save

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end

  def expect_error_for_users(users)
    subject = Admin::Impersonation.new(user_finder: double(find_users: users))

    result = subject.save

    expect(result).to be false
    expect(subject.errors.full_messages).to be_present
  end
end
