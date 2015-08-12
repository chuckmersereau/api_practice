silence_warnings do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end
OmniAuth.config.full_host = (Rails.env.development? ? 'http://' : 'https://') + ActionMailer::Base.default_url_options[:host]
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV.fetch('TWITTER_KEY'), ENV.fetch('TWITTER_SECRET')
  provider :facebook, ENV.fetch('FACEBOOK_KEY'), ENV.fetch('FACEBOOK_SECRET'), :scope => 'user_about_me,user_activities,user_birthday,friends_birthday,user_education_history,friends_education_history,user_hometown,friends_hometown,user_interests,friends_interests,user_likes,friends_likes,user_location,friends_location,user_relationships,friends_relationships,user_relationship_details,friends_relationship_details,user_religion_politics,friends_religion_politics,user_work_history,friends_work_history,friends_website,read_mailbox,read_stream,publish_stream,manage_pages,friends_about_me,friends_activities,'
  provider :linkedin, ENV.fetch('LINKEDIN_KEY'), ENV.fetch('LINKEDIN_SECRET')
  provider :google_oauth2, ENV.fetch('GOOGLE_KEY'), ENV.fetch('GOOGLE_SECRET'), :name => 'google', :scope => 'userinfo.email,userinfo.profile,https://www.google.com/m8/feeds,https://mail.google.com/,https://www.googleapis.com/auth/calendar', access_type: 'offline', prompt: 'consent select_account'
  provider :cas, name: 'relay', url: 'https://signin.relaysso.org/cas'
  provider :cas, name: 'key', url: 'https://thekey.me/cas'
  provider :cas, name: 'admin', url: 'https://signin.relaysso.org/cas'
  provider :prayer_letters, ENV.fetch('PRAYER_LETTERS_CLIENT_ID'), ENV.fetch('PRAYER_LETTERS_CLIENT_SECRET'), scope: 'contacts.read contacts.write'
  provider :pls, ENV.fetch('PLS_CLIENT_ID'), ENV.fetch('PLS_CLIENT_SECRET'), scope: 'contacts.read contacts.write'
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
