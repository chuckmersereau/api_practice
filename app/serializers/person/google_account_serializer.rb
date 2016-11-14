class Person::GoogleAccountSerializer < ActiveModel::Serializer
  attributes :id, :remote_id, :person_id, :token, :refresh_token,
             :expires_at, :valid_token, :created_at, :updated_at,
             :email, :authenticated, :primary, :downloading, :last_download,
             :last_email_sync, :notified_failure
end
