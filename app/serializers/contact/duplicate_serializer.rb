class Contact::DuplicateSerializer < ActiveModel::Serializer
  has_many :contacts
end
