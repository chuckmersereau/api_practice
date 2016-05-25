require 'spec_helper'

describe MailChimpSyncWorker, '#perform' do
  it 'subscribes users signed in recently' do
    user = create(:person_with_email, sign_in_count: 1, current_sign_in_at: 1.day.ago)
    create_member =
      stub_request(:put, 'https://apikey:asdf-us6@us6.api.mailchimp.com/3.0/'\
                   'lists/asdf/members/d4c74594d841139328695756648b6bd6')

    subject.perform

    expect(user.reload.subscribed_to_updates).to be true
    expect(create_member).to have_been_requested
  end

  it 'unsubscribes users signed in a while ago' do
    user = create(:person_with_email, sign_in_count: 1, subscribed_to_updates: true,
                                      current_sign_in_at: (MailChimpSyncWorker::CURRENT_USER_RANGE - 1.day))
    delete_member =
      stub_request(:delete, 'https://apikey:asdf-us6@us6.api.mailchimp.com/3.0/'\
                   'lists/asdf/members/d4c74594d841139328695756648b6bd6')

    subject.perform

    expect(user.reload.subscribed_to_updates).to be_nil
    expect(delete_member).to have_been_requested
  end
end
