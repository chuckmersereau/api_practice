class Person::OrganizationAccountSerializer < ApplicationSerializer
  type :organization_accounts

  attributes :disable_downloads,
             :last_download,
             :locked_at,
             :remote_id,
             :token,
             :username

  belongs_to :organization
  belongs_to :person
end
