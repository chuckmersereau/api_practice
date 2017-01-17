class Person::DuplicateSerializer < ActiveModel::Serializer
  has_one :person
  has_one :dup_person
  has_one :shared_contact
  has_many :people
end
