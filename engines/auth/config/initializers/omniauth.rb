require 'omniauth'
require 'omniauth-google-oauth2'
require 'omniauth-mailchimp'
require 'omniauth-prayer-letters'

Auth::Engine.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch('GOOGLE_KEY'),
           ENV.fetch('GOOGLE_SECRET'),
           name: 'google',
           scope: 'userinfo.email,userinfo.profile,https://www.google.com/m8/feeds,https://mail.google.com/,https://www.googleapis.com/auth/calendar',
           access_type: 'offline',
           prompt: 'consent select_account'
  provider :prayer_letters,
           ENV.fetch('PRAYER_LETTERS_CLIENT_ID'),
           ENV.fetch('PRAYER_LETTERS_CLIENT_SECRET'),
           scope: 'contacts.read contacts.write'
  provider :mailchimp,
           ENV.fetch('MAILCHIMP_CLIENT_ID'),
           ENV.fetch('MAILCHIMP_CLIENT_SECRET')
end

OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
