class Person::OrganizationAccountSerializer < ApplicationSerializer
  attributes :authenticated,
             :disable_downloads,
             :downloading,
             :last_download,
             :locked_at,
             :remote_id,
             :token,
             :username,
             :valid_credentials

  belongs_to :organization
  belongs_to :person
end
