class EmailAddressSerializer < ApplicationSerializer
  attributes :email,
             :location,
             :primary,
             :historic,
             :source,
             :valid_values
end
