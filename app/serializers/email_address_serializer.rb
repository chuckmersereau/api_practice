class EmailAddressSerializer < ApplicationSerializer
  attributes :email,
             :historic,
             :primary
end
