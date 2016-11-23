class Person::GoogleAccountSerializer < ApplicationSerializer
  attributes :authenticated,
             :downloading,
             :email,
             :expires_at,
             :last_download,
             :last_email_sync,
             :notified_failure,
             :person_id,
             :primary,
             :refresh_token,
             :remote_id,
             :token,
             :valid_token
end
