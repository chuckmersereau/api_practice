class EmailAddressSerializer < ApplicationSerializer
  attributes :email,
             :location,
             :primary,
             :historic
end
