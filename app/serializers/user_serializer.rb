class UserSerializer < ApplicationSerializer
  attributes :first_name,
             :last_name,
             :preferences

  has_many :account_lists

  belongs_to :master_person
end
