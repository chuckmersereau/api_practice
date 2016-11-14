class Person::KeyAccountSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :remote_id,
             :authenticated, :created_at, :updated_at,
             :downloading, :last_download, :primary
end
