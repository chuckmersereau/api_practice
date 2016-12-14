class Person::GoogleAccountSerializer < ApplicationSerializer
  type :google_accounts

  attributes :authenticated,
             :downloading,
             :email,
             :expires_at,
             :last_download,
             :last_email_sync,
             :notified_failure,
             :primary,
             :refresh_token,
             :remote_id,
             :token,
             :valid_token

  belongs_to :person
end
