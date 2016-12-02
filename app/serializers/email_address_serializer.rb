class EmailAddressSerializer < ApplicationSerializer
  attributes :email,
             :location,
             :primary,
             :historic

  belongs_to :person
end
