class Contact::ChurchNamesSerializer < ActiveModel::Serializer
  type 'church_names'
  attributes :church_name
end
