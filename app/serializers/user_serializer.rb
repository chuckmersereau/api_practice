require 'digest/sha1'

class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :master_person_id, :preferences, :created_at, :updated_at

  has_many :account_lists
end
