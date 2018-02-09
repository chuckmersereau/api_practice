require 'warden'
Warden::Manager.serialize_into_session(&:id)
Warden::Manager.serialize_from_session do |id|
  User.find_by!(id: id)
end
