class Person::OrganizationAccountSerializer < ApplicationSerializer
  attributes :authenticated,
             :disable_downloads,
             :downloading,
             :last_download,
             :locked_at,
             :organization_id,
             :person_id,
             :remote_id,
             :token,
             :username,
             :valid_credentials

  belongs_to :organization
end
