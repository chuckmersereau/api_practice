class Person::OrganizationAccountSerializer < ActiveModel::Serializer
  attributes :id, :username, :password, :person_id, :organization_id, :remote_id,
             :authenticated, :valid_credentials, :created_at, :updated_at,
             :downloading, :last_download, :token, :locked_at, :disable_downloads

  belongs_to :organization
end
