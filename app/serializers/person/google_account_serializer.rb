class Person::GoogleAccountSerializer < ApplicationSerializer
  type :google_accounts

  attributes :email,
             :expires_at,
             :last_download,
             :last_email_sync,
             :primary,
             :refresh_token,
             :remote_id,
             :token

  belongs_to :person
end
