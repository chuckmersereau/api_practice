require 'spec_helper'

describe User::MailChimpManager do
  context '#subscribe' do
    it 'does not error on a 400 message about an invalid email address' do
      user = create(:user, subscribed_to_updates: true, email: 'j@t.co')
      url = 'https://apikey:asdf-us6@us6.api.mailchimp.com/3.0/'\
        'lists/asdf/members/47f62523d9b40ad2176baf884072aca5'

      err = 'j@t.co looks fake or invalid, please enter a real email address.'
      create_request = stub_request(:put, url)
                       .to_return(status: 400, body: { detail: err }.to_json)

      User::MailChimpManager.new(user).subscribe

      expect(user.reload.subscribed_to_updates).to be false
      expect(create_request).to have_been_made
    end
  end

  context '#unsubscribe' do
    it 'does not error on a 404 message but marks user as unsubscribed' do
      user = create(:user, subscribed_to_updates: true, email: 'j@t.co')
      url = 'https://apikey:asdf-us6@us6.api.mailchimp.com/3.0/'\
        'lists/asdf/members/47f62523d9b40ad2176baf884072aca5'
      delete_request = stub_request(:delete, url).to_return(status: 404)

      User::MailChimpManager.new(user).unsubscribe

      expect(user.reload.subscribed_to_updates).to be_nil
      expect(delete_request).to have_been_made
    end
  end
end
