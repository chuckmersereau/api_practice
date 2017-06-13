class Person::GoogleAccountSerializer < ApplicationSerializer
  type :google_accounts

  has_many :contact_groups

  attributes :email,
             :expires_at,
             :last_download,
             :last_email_sync,
             :primary,
             :remote_id,
             :token_expired

  def token_expired
    object.token_expired?
  end
end
