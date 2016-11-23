class UserSerializer < ApplicationSerializer
  attributes :first_name,
             :last_name,
             :master_person_id,
             :preferences

  has_many :account_lists
end
