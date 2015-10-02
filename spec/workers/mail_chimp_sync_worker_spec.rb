require 'spec_helper'

describe MailChimpSyncWorker do
  it 'subscribes users signed in recently' do
    user = create(:person_with_email, sign_in_count: 1, current_sign_in_at: 1.day.ago)
    expect(subject.gb).to receive(:list_subscribe)
    subject.perform
    expect(user.reload.subscribed_to_updates).to be true
  end

  it 'unsubscribes users signed in a while ago' do
    user = create(:person_with_email, sign_in_count: 1, subscribed_to_updates: true,
                                      current_sign_in_at: (MailChimpSyncWorker::CURRENT_USER_RANGE - 1.day))
    expect(subject.gb).to receive(:list_unsubscribe)
    subject.perform
    expect(user.reload.subscribed_to_updates).to be_nil
  end
end
